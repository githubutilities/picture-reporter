#!/usr/bin/perl

# Program report.pl

# (c) Gary C. Kessler, 2012, 2013

# report is a simple program to take directories of pictures
# and create an HTML-formatted report. Designed for digital
# forensics examiners...

# ********************************************************
# MAIN PROGRAM BLOCK
# ********************************************************

# Initialize global variables

$version = "1.4";
$build_date = "12 January 2013";

$verbose = 0;     # Verbose mode is off (0) by default; turn on (1) with -v switch
$caseroot = "";   # Case root directory set with -r switch

print "\nPicture Reporter V$version - Gary C. Kessler ($build_date)\n\n";

# Parse command line switches.
# If user has supplied the -h, -v, or an illegal switch, the subroutine
# returns a value of 1 and the program stops.

if (parsecommandline ())
  { exit 1; };

# Read .ini file, if present

if (-e "report.ini")
    {
    open (INPUT,"<","report.ini");
    $line = <INPUT>;
    close INPUT;
    chomp ($line);
    ($picsPerRow,$height,$width)=split(/\,/,$line);
    }
  else
    {
    $picsPerRow = 4;
    $height = 200;
    $width = 200;
    }

if ($verbose == 1)
  {
  print "** Images/row = $picsPerRow, image height = $height, image width $width\n";
  print "** caseroot $caseroot\n\n";
  }

$num_dirs = 0;
$num_files = 0;

# Open the case's photo root directory and get the name of all files
# in that directory

opendir (IMD, $caseroot) || die ("Cannot open directory $caseroot");
@dir_list = readdir (IMD);
closedir (IMD);

# Start building report's HTML code

$reportLogo = $caseroot . "/" . $logoFile;

open (REPORT,">",$caseroot."/report.html");
print REPORT "<html>\n<head>\n<title>Case #$caseNum</title>\n</head>\n<body>\n";
if (-e $reportLogo)
    { print REPORT "<br>\n<center><img src=\"$logoFile\"></center>\n"; }
print REPORT "<br>\n<h2 align=\"center\">CASE FILE REPORT</h2>\n";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
$year += 1900;
$mon += 1;

print REPORT "<table cellspacing=40 cellpadding=5 align=center>\n<tr>\n";
print REPORT "<td>\n<b>Examiner's Name:</b> $examinerName<br>\n<b>Examiner's Agency:</b> $examinerAgency<br>\n";
  print REPORT "<b>Phone Number:</b> $examinerPhone<br>\n<b>E-mail:</b> $examinerEmail<br><br>\n";
  printf (REPORT "<b>Report Date:</b> %02d/%02d/%4d</td>\n", $mon, $mday, $year);
print REPORT "<td>\n<b>Case Number:</b> $caseNum<br>\n<b>Evidence Number:</b> $evidenceNum<br>\n";
   print REPORT "\n<b>Investigator's Name:</b> $investigatorName<br>\n<b>Investigator's Agency:</b> $investigatorAgency<br><br>\n";
   printf (REPORT "<b>Report Time:</b> %02d:%02d</td></tr>\n", $hour, $min);
if ($comments ne "")
  { print REPORT "<tr>\n<td colspan=2>\n<b>Notes:</b> $comments</td>\n</tr>\n"; }
print REPORT "</table>\n";

# Now, cycle through all of the files in the case root. We will
# ignore all files and open all directories (except . and ..)

foreach $dir (@dir_list)
  {
  unless ( ($dir eq ".") || ($dir eq "..") )
    {

# We are now in one of the photo subdirectories. Get the list of files
# in this directory.

    opendir (IMD, $caseroot."/".$dir);
    @file_list = readdir (IMD);
    $list_size = @file_list;
    closedir (IMD);

# This section is a bit if a kludge. An "empty" directory will contain two entries, namely "." and
# "..". In addition, directories created in a Mac may contain ".DS_Store" and Windows systems may have
# "Thumbs.db". We want to skip all of these files!

# $skipsize = 2, which is the number of directory entries that still signify an "empty" directory.
# Check directories to see if they also have .DS_Store and/or Thumbs.db, and increment $skipsize
# as necessary.

   $skipsize = 2;
   if ($list_size > 2)
     {
     foreach $file (@file_list)
       {
       if ($file eq ".DS_Store") { $skipsize++; }
       if ($file eq "Thumbs.db") { $skipsize++; }
       }
     }

# Skip empty directories.

    if ($list_size > $skipsize)
      {
      print REPORT "<h3 align=\"center\">Directory: $dir</h3><br>\n";
      print REPORT "<table cellspacing=5 cellpadding=5 align=center>\n";
      print REPORT "<tr>\n";
      $num_dirs++;
      $i = 0;

# Cycle through all of the files in the photo subdirectory (except
# . and ..) and prepare the output. (NOTE that we only get inside
# this loop for directories

      foreach $file (@file_list)
        {
        unless ( ($file eq ".") || ($file eq "..") || ($file eq ".DS_Store") || ($file eq "Thumbs.db") )
          {
          $num_files++;
          if ($verbose == 1)
            { print "** $dir: $file\n"; }
          if ($i%$picsPerRow == 0 && $i != 0)
            {
            print REPORT "</tr>\n<tr>\n";
            }
          $i++;
          print REPORT "<td>\n";
          print REPORT "<a href=\"$dir/$file\"><img src=\"$dir/$file\" height=$height width=$width></a><br>\n";
          print REPORT "$i) $file</td>\n";
          }
        }

      if ($i%$picsPerRow != 0)
        { print REPORT "</tr>\n"; }
      print REPORT "</table>\n<br>\n";
      }
    }
  }

print REPORT "<center>\n<h3>=== END OF REPORT ===</h3>\n";
   print REPORT "<h5>(c) Gary Kessler Associates, 2012-2013, v. $version</h5>\n</center>\n";
   print REPORT "</body>\n</html>\n";
close (REPORT);
print "\nDone! $num_dirs directories and $num_files files processed!\n\n";


# ********************************************************
# *****           SUBROUTINE BLOCKS                  *****
# ********************************************************

# ********************************************************
# help_text
# ********************************************************

# Display the help file

sub help_text
{
print<< "EOT";
Program usage: report.pl [-r case_root] [-e examiner_info] [-c case_info] [-v]
               report.pl [-h]

 where: -r is the root directory with the case files (*** This should be the first parameter!! ***)
        -e is the file containing identifying information for the examiner
        -c is the file containing stored case information
        -v turns on verbose output
        -h prints this help file

If the -r, -e, or -c switches are missing, the program will ask for the
file names.

If you provide a file containing examiner information, it should have five
lines, with the following information:

Examiner name
Examiner agency
Examiner phone number
Examiner e-mail address
Agency logo

If you provide a file containing case information, it should have five lines,
with the following information:

Case number
Evidence identifier
Investigator name
Investigator agency
Comments/notes

In the two files above, leave a blank line for any information you wish to
skip.

EOT
return;
}

# ********************************************************
# parsecommandline
# ********************************************************

# Parse command line for file name, if present. Query
# user for any missing information

# Return $state = 1 to indicate that the program should stop
# immediately (switch -h)

sub parsecommandline
{
my $state = 0;
my $examiner_file = "";
my $case_file = "";

# Parse command line switches ($ARGV array of length $#ARGV)

if ($#ARGV >= 0)
  { 
  for ($i = 0; $i <= $#ARGV; $i++)
    {
    PARMS:
      {
      $ARGV[$i] eq "-r" && do
         {
         $caseroot = $ARGV[$i+1];
         $i++;
         last PARMS;
         };
      $ARGV[$i] eq "-e" && do
         {
         $examiner_file = $ARGV[$i+1];
         $i++;
         last PARMS;
         };
      $ARGV[$i] eq "-c" && do
         {
         $case_file = $ARGV[$i+1];
         $i++;
         last PARMS;
         };
      $ARGV[$i] eq "-v" && do
         {
         $verbose = 1;
         last PARMS;
         };
      $ARGV[$i] eq "-h" && do
         {
         help_text();
         $state = 1;
         return $state;
         };

      do
         {
         print "Invalid parameter \"$ARGV[$i]\".\n\n";
         print "Usage: report.pl [-r case_root] [-e examiner_info] [-c case_info] [-v]\n";
         print "       report.pl [-h]\n\n";
         $state = 1;
         return $state;
         };
      };
    };
  };

# Read files or prompt for missing information

# First get case root directory

if ($caseroot eq "")
  {
  print "\nEnter the case root directory: \n";
  chomp ($caseroot = <STDIN>);
  }

# Now check examiner information

if ($examiner_file ne "")
    {
    open (INPUT, "<", $caseroot."/".$examiner_file) || die ("Cannot open examiner file $caseroot/$examinerfile");
    chomp ($examinerName = <INPUT>);
    chomp ($examinerAgency = <INPUT>);
    chomp ($examinerPhone = <INPUT>);
    chomp ($examinerEmail = <INPUT>);
    chomp ($logoFile = <INPUT>);
    close (INPUT);
    }
  else
    {
    print "\nEnter examiner information...\n";
    print "\n  Enter examiner's name: ";
    chomp ($examinerName = <STDIN>);
    print "\n  Enter examiner's agency: ";
    chomp ($examinerAgency = <STDIN>);
    print "\n  Enter examiner's contact phone number: ";
    chomp ($examinerPhone = <STDIN>);
    print "\n  Enter examiner's e-mail address: ";
    chomp ($examinerEmail = <STDIN>);
    print "\n  Enter the name of the file with the logo of the examiner's agency: ";
    chomp ($logoFile = <STDIN>);

    print "\n\nWriting examiner information to '$caseroot/examiner.txt' file...\n\n";
    open (OUTPUT, ">", $caseroot."/examiner.txt");
    print OUTPUT "$examinerName\n";
    print OUTPUT "$examinerAgency\n";
    print OUTPUT "$examinerPhone\n";
    print OUTPUT "$examinerEmail\n";
    print OUTPUT "$logoFile\n";
    close (OUTPUT);
    }

# Finally, check case information

if ($case_file ne "")
    {
    open (INPUT, "<", $caseroot."/".$case_file) || die ("Cannot open case file $caseroot/$casefile");
    chomp ($caseNum = <INPUT>);
    chomp ($evidenceNum = <INPUT>);
    chomp ($investigatorName = <INPUT>);
    chomp ($investigatorAgency = <INPUT>);
    chomp ($comments = <INPUT>);
    close (INPUT);
    }
  else
    {
    print "\nEnter case information...\n";
    print "\n  Enter the case number/name: ";
    chomp ($caseNum = <STDIN>);
    print "\n  Enter the evidence number/identifier: ";
    chomp ($evidenceNum = <STDIN>);
    print "\n  Enter investigator's name: ";
    chomp ($investigatorName = <STDIN>);
    print "\n  Enter investigator agency: ";
    chomp ($investigatorAgency = <STDIN>);
    print "\n  Enter any additional notes or comments: ";
    chomp ($comments = <STDIN>);

    print "\n\nWriting case information to '$caseroot/case.txt' file...\n";
    open (OUTPUT, ">", $caseroot."/case.txt");
    print OUTPUT "$caseNum\n";
    print OUTPUT "$evidenceNum\n";
    print OUTPUT "$investigatorName\n";
    print OUTPUT "$investigatorAgency\n";
    print OUTPUT "$comments\n";
    close (OUTPUT);
    }

return $state;
}

