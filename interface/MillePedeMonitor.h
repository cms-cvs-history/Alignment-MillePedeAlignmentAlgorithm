#ifndef MILLEPEDEMONITOR_H
#define MILLEPEDEMONITOR_H

/// \class MillePedeMonitor
///
/// monitoring of MillePedeAlignmentAlgorithm and its input tracks
///
///  \author    : Gero Flucke
///  date       : October 2006
///  $Revision: 1.4.2.1 $
///  $Date: 2007/04/30 14:19:53 $
///  (last update by $Author: flucke $)

#include "DataFormats/CLHEP/interface/AlgebraicObjects.h"

#include "Alignment/CommonAlignmentAlgorithm/interface/ReferenceTrajectoryBase.h"

#include "FWCore/MessageLogger/interface/MessageLogger.h"

#include "TrackingTools/TransientTrackingRecHit/interface/TransientTrackingRecHit.h"

#include <vector>
#include <TString.h>
#include <TH1.h>
#include <TH2.h>

class TH1;
class TH2;
class TDirectory;
class Trajectory;

namespace reco {
  class Track;
}

class Alignable;
class AlignableDetOrUnitPtr;
class TrajectoryStateOnSurface;

/***************************************
****************************************/
class MillePedeMonitor
{
 public:
  // book histograms in constructor
  MillePedeMonitor(const char *rootFile = "trackMonitor.root");
  MillePedeMonitor(TDirectory *rootDir);
  // writes histograms in destructor
  ~MillePedeMonitor(); // non-virtual destructor: not intended to be parent class

  void fillTrack(const reco::Track *track, const Trajectory *traj);
  void fillRefTrajectory(const ReferenceTrajectoryBase::ReferenceTrajectoryPtr &refTrajPtr);
  void fillDerivatives(const TransientTrackingRecHit::ConstRecHitPointer &recHit,
		       const std::vector<float> &localDerivs,
		       const std::vector<float> &globalDerivs, bool isY);
  void fillResiduals(const TransientTrackingRecHit::ConstRecHitPointer &recHit,
		     const TrajectoryStateOnSurface &tsos, unsigned int nHit,
		     float residuum, float sigma, bool isY);
  void fillFrameToFrame(const AlignableDetOrUnitPtr &aliDet, const Alignable *ali);

 private:
  bool init(TDirectory *directory);
  bool equidistLogBins(double* bins, int nBins, double first, double last) const;
  void fillResidualHists(const std::vector<TH1*> &hists, float phiSensToNorm,
			 float residuum, float sigma);
  void fillResidualHitHists(const std::vector<TH1*> &hists, float angle,
			    float residuum, float sigma, unsigned int nHit);

  template <class OBJECT_TYPE>  
    int GetIndex(const std::vector<OBJECT_TYPE*> &vec, const TString &name);
  template <class OBJECT_TYPE>  
  std::vector<OBJECT_TYPE*> cloneHists(const std::vector<OBJECT_TYPE*> &orgs,
				       const TString &namAd, const TString &titAd) const;

  TDirectory *myRootDir;
  bool        myDeleteDir; 

  std::vector<TH1*> myTrackHists1D;
  std::vector<TH2*> myTrackHists2D;
  std::vector<TH1*> myTrajectoryHists1D;
  std::vector<TH2*> myTrajectoryHists2D;
  std::vector<TH2*> myDerivHists2D;
  std::vector<TH2*> myResidHists2D;
  std::vector<std::vector<TH1*> > myResidHistsVec1DX;///[0]=all [1]=TPB [2]=TPE [3]=TIB [4]=TID [5]=TOB [6]=TEC
  std::vector<std::vector<TH1*> > myResidHistsVec1DY;///[0]=all [1]=TPB [2]=TPE [3]=TIB [4]=TID [5]=TOB [6]=TEC
  std::vector<TH1*> myResidHitHists1DX;
  std::vector<TH1*> myResidHitHists1DY;


  std::vector<TH2*> myFrame2FrameHists2D;

};

template <class OBJECT_TYPE>  
int MillePedeMonitor::GetIndex(const std::vector<OBJECT_TYPE*> &vec, const TString &name)
{
  int result = 0;
  for (typename std::vector<OBJECT_TYPE*>::const_iterator iter = vec.begin(), iterEnd = vec.end();
       iter != iterEnd; ++iter, ++result) {
    if (*iter && (*iter)->GetName() == name) return result;
  }
  edm::LogError("Alignment") << "@SUB=MillePedeMonitor::GetIndex" << " could not find " << name;
  return -1;
}

template <class OBJECT_TYPE>  
std::vector<OBJECT_TYPE*> MillePedeMonitor::cloneHists(const std::vector<OBJECT_TYPE*> &orgs,
						       const TString &namAd,
						       const TString &titAd) const
{
  // OBJECT_TYPE required to have methods Clone(const char*), GetName(), SetTitle(const char*) and GetTitle()
  std::vector<OBJECT_TYPE*> result;
  for (typename std::vector<OBJECT_TYPE*>::const_iterator iter = orgs.begin(), iterEnd = orgs.end();
       iter != iterEnd; ++iter) {
    if (!(*iter)) continue;
    result.push_back(static_cast<OBJECT_TYPE*>((*iter)->Clone(namAd + (*iter)->GetName())));
    if (result.back()) result.back()->SetTitle((*iter)->GetTitle() + titAd);
    else edm::LogError("Alignment") <<"@SUB=MillePedeMonitor::cloneHists"
				    << "out of memory?";
  }
  
  return result;
}
#endif
