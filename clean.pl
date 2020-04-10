#!/usr/bin/perl
use strict;
use warnings;
use HTML::ExtractContent;
use File::Basename;
use utf8;
# get directory and initialize modules
my $directory = $ARGV[0] or die "directory belum diisi"; #example : ./data not ./data/
my @files = `find $directory/*.html`;
my $extractor = HTML::ExtractContent->new;
# Directory where clean data are stored, its better to set this in config file
my $PATHCLEAN = "./data";

my @count=(0,0);
my $category;
my $process=0;
print "On process get data from $ARGV[0] ...\n";
foreach my $file(@files){ 
    $process++;
    my $fileout = basename($file);
    
    $fileout = SourceFile($fileout);
    # open file
    open OUT, "> $fileout" or die "Cannot Open File!!!";
    binmode(OUT, "encoding(UTF-8)");

    my $html = `cat $file`;
    $html =~ s/\^M//g;

    # get URL
    if ($html =~ /property="og:url" content="(.*?)"/) {
        print OUT "<url>$1</url>\n";
    }

    # get TITLE
    if($html =~ /<title.*?>(.*?)<\/title>/){
        my $title = $1;

        $title = clean_str($title);
        print OUT "<title>$title</title>\n";
    }

    # get BODY (Content)
    $extractor->extract($html);
    my $content = $extractor->as_text;
    $content = clean_str($content);
    split_content($content);

    # close file
    close OUT;
    if($process % 1000 == 0){
        print "\nDone : $process\n";
    }
}

print "\nSuccess...\n";

# split content to top, middle, and bottom
sub split_content{
    my @contents = split /\. /,$_[0];
    my $length = @contents;
    my $part = int($length/5);
    my @sections=('','','','','');
    if($part != 0){
        my ($index , $iterate, $pattern) = (0 , 0, $length % 5);
        my $isIterate = 0 eq 0;
        foreach my $content (@contents){
            $sections[$index].=$content.". ";
            $iterate++;
            if($iterate % $part == 0){
                if($index + 1 <= $pattern && $isIterate){
                    $iterate--;
                    $isIterate = 1 eq 0;
                }else{
                    $index++;
                    $isIterate = 0 eq 0;
                }
            }
        }
        $index=1;
        foreach my $section(@sections){
            print OUT "<sec$index>$section</sec$index>\n";
            $index++;
        }
    }else{
        print OUT "<sec1>unknown</sec1>\n<sec2>unknown</sec2>\n<sec3>unknown</sec3>\n<sec4>unknown</sec4>\n<sec5>unknown</sec5>\n";
    }
}

# clean string using regex
sub clean_str {
    my $str = shift;
    $str =~ s/>//g;
    $str =~ s/&.*?;//g;
    $str =~ s/[\]\|\[\@\#\$\%\*\&\\\(\)\"]+//g;
    $str =~ s/-/ /g;
    $str =~ s/\n+//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    $str =~ s/^$//g;
    return $str;
}

sub SourceFile{
    my $fileout = $_[0];

    if($fileout =~ /tekno/){
        $category = 0;
    }elsif($fileout =~ /travel/){
        $category = 1;
    }
    $count[$category]++;
    if($count[$category] > 15000){
        return "$PATHCLEAN/dictionary/$fileout";
    }elsif($count[$category]>10000){
        return "$PATHCLEAN/test/$fileout";
    }
    return "$PATHCLEAN/train/$fileout";
}