#!/usr/local/bin/perl
#     R. Mankel, DESY Hamburg     08-Oct-2007
#     A. Parenti, DESY Hamburg    29-Mar-2008
#     $Revision: 1.14 $
#     $Date: 2008/03/25 16:15:57 $
#
#  Setup local mps database
#  
#
#  Usage:
#
#  mps_setup.pl batchScript cfgTemplate infiList nJobs class jobname [mergeScript] [mssDir]
#
# class can be: 8nm,1nh,8nh,1nd,2nd,1nw,2nw (lxplus)
#               dedicated                   (cmsalca,cmscaf)

use lib './mpslib';
use Mpslib;

$batchScript = "undefined";
$cfgTemplate = "undefined";
$infiList = "undefined";
$nJobs = 0;
$class = "S";
$addFiles = "";
$driver = "";
$mergeScript = "";
$mssDir = "";
$append = 0;

# parse the arguments
while (@ARGV) {
  $arg = shift(ARGV);
  if ($arg =~ /\A-/) {  # check for option 
    if ($arg =~ "h") {
      $helpwanted = 1;
    }
    elsif ($arg =~ "d") {
      $localdir = 1;
    }
    elsif ($arg =~ "u") {
      $updateDb = 1;
    }
    elsif ($arg =~ "m") {
      $driver = "merge";
      print "option sets mode to $driver\n";
    }
    elsif ($arg =~ "a" && -r "mps.db") {
      $append = 1;
      print "option sets mode to append\n";    
    }

    $optionstring = "$optionstring$arg";
  }
  else {                # parameters not related to options
    $i = $i + 1;
    if ($i eq 1) {
      $batchScript = $arg;
    }
    if ($i eq 2) {
      $cfgTemplate = $arg;
    }
    if ($i eq 3) {
      $infiList = $arg;
    }
    elsif ($i eq 4) {
      $nJobs = $arg;
    }
    elsif ($i eq 5) {
      $class = $arg;
    }
    elsif ($i eq 6) {
      $addFiles = $arg;
    }
    elsif ($i eq 7) {
      $mergeScript = $arg;
    }
    elsif ($i eq 8) {
      $mssDir = $arg;
    }
  }
}

# test input parameters
if ($nJobs eq 0 or $helpwanted != 0 ) {
  print "Usage:\n  mps_setup.pl [options] batchScript cfgTemplate infiList nJobs class jobname [mergeScript] [mssDir]";
  print "\nKnown options:";
  print "  \n -m   Setup pede merging job.";
  print "  \n -a   Append jobs to existing list.\n";
  exit 1;
}

unless (-r $batchScript) {
  print "Bad batchScript script name $batchScript\n";
  exit 1;
}
unless (-r $cfgTemplate) {
  print "Bad cfg template file name $cfgTemplate\n";
  exit 1;
}
unless (-r $infiList) {
  print "Bad input list file $infiList\n";
  exit 1;
}
unless (index("lxplus cmsalca cmscaf 8nm 1nh 8nh 1nd 2nd 1nw 2nw dedicated",$class)>-1) {
  print "Bad job class $class\n";
  exit 1;
}
if ($driver eq "merge") {
  if ($mergeScript eq "") {
    $mergeScript = $batchScript . "merge";
  }
  unless (-r $mergeScript) {
    print "Bad merge script file name $mergeScript\n";
    exit 1;
  }
}
if ($mssDir ne "") {
  $testMssDir = `nsls -d $mssDir`;
  chomp $testMssDir;
  if ($testMssDir eq "") {
    print "Bad MSS directory name $mssDir\n";
  }
}

$sdir = get_sdir();

# Create the job directories
my $nJobExist="";
if ($append==1 && -d "jobData") {
# Append mode, and "jobData" exists
  $nJobExist = `ls jobData | grep 'job[0-9][0-9][0-9]' | tail -1 | awk '{gsub(\"job\",\"\"); print}'`;
}

if ($nJobExist eq "" || $nJobExist <=0 || $nJobExist>999) {
# Delete all
  system "rm -rf jobData";
  system "mkdir jobData";
  $nJobExist = 0;
}

for ($j = 1; $j <= $nJobs; ++$j) {
  $i = $j+$nJobExist;
  $jobdir = sprintf "job%03d",$i;
  print "jobdir $jobdir\n";
  system "mkdir jobData/$jobdir";
}

# build the absolute job directory path (needed by mps_script)
$thePwd = `pwd`;
chomp $thePwd;
$theJobData = "$thePwd/jobData";
print "theJobData= $theJobData \n";

if ($append == 1) {
# save current values
  my $tmpNJobs = $nJobs;
  my $tmpInfiList = $infiList;
  my $tmpDriver = $driver;

# Read DB file
  read_db();

# check if last job is a merge job
  if (@JOBDIR[$nJobs] eq "jobm") {
# remove the merge job
    pop @JOBDIR;
    pop @JOBID;
    pop @JOBSTATUS;
    pop @JOBNTRY;
    pop @JOBRUNTIME;
    pop @JOBNEVT;
    pop @JOBHOST;
    pop @JOBINCR;
    pop @JOBREMARK;
    pop @JOBSP1;
    pop @JOBSP2;
    pop @JOBSP3;
  }

# Restore variables
  $nJobs = $tmpNJobs;
  $infiList = $tmpInfiList;
  $driver = $tmpDriver;
}


# Create (update) the local database
for ($j = 1; $j <= $nJobs; ++$j) {
  $i=$j+$nJobExist;
  $theJobDir = sprintf "job%03d",$i;
  push @JOBDIR,$theJobDir;
  push @JOBID,0;
  push @JOBSTATUS,"SETUP";
  push @JOBNTRY,0;
  push @JOBRUNTIME,0;
  push @JOBNEVT,0;
  push @JOBHOST,"";
  push @JOBINCR,0;
  push @JOBREMARK,"";
  push @JOBSP1,"";
  push @JOBSP2,"";
  push @JOBSP3,"";
  # create the split card files
  print "$sdir/mps_split.pl $infiList $j $nJobs >jobData/$theJobDir/theSplit\n";
  system "$sdir/mps_split.pl $infiList $j $nJobs >jobData/$theJobDir/theSplit";
  if ($?) {
    print "              split failed\n";
    @JOBSTATUS[$i-1] = "FAIL";
  }
  $theIsn = sprintf "%03d",$i;
  print "$sdir/mps_splice.pl $cfgTemplate jobData/$theJobDir/theSplit jobData/$theJobDir/the.cfg $theIsn\n";
  system "$sdir/mps_splice.pl $cfgTemplate jobData/$theJobDir/theSplit jobData/$theJobDir/the.cfg $theIsn";
  # create the run script
  print "$sdir/mps_script.pl $batchScript  jobData/$theJobDir/theScript.sh $theJobData/$theJobDir the.cfg jobData/$theJobDir/theSplit $theIsn $mssDir\n";
  system "$sdir/mps_script.pl $batchScript  jobData/$theJobDir/theScript.sh $theJobData/$theJobDir the.cfg jobData/$theJobDir/theSplit $theIsn $mssDir";
}

# create the merge job entry. This is always done. Whether it is used depends on the "merge" option.
$theJobDir = "jobm";
push @JOBDIR,$theJobDir;
push @JOBID,0;
push @JOBSTATUS,"SETUP";
push @JOBNTRY,0;
push @JOBRUNTIME,0;
push @JOBNEVT,0;
push @JOBHOST,"";
push @JOBINCR,0;
push @JOBREMARK,"";
push @JOBSP1,"";
push @JOBSP2,"";
push @JOBSP3,"";

# if merge mode, create the directory and set up contents
if ($driver eq "merge") {

  system "rm -rf jobData/jobm";
  system "mkdir jobData/jobm";
  print "Create dir jobData/jobm\n";

  # We want to merge old and new jobs
  my $nJobsMerge = $nJobs+$nJobExist;

  # create  merge job cfg
  print "$sdir/mps_merge.pl $cfgTemplate jobData/jobm/alignment_merge.cfg $theJobData/jobm $nJobsMerge\n";
  system "$sdir/mps_merge.pl $cfgTemplate jobData/jobm/alignment_merge.cfg $theJobData/jobm $nJobsMerge";

  # create merge job script
  print "$sdir/mps_scriptm.pl $mergeScript jobData/jobm/theScript.sh $theJobData/jobm alignment_merge.cfg $nJobsMerge $mssDir\n";
  system "$sdir/mps_scriptm.pl $mergeScript jobData/jobm/theScript.sh $theJobData/jobm alignment_merge.cfg $nJobsMerge $mssDir";
}

write_db();
read_db();
print_memdb();
