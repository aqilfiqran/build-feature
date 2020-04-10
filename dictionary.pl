#!/usr/bin/perl
# Aqil Fiqran Dzi'Ul Haq
# 1708107010026

use Lingua::EN::Ngram;
use strict;

# Path output and input initialize
my $PATH = './dictionary';
my $DIRECTORY = $ARGV[0];
if(!$DIRECTORY){
    print "Cara jalankan: $0 <directory>\n";
    exit;
}

# Initialize stopword and hash word
my %stopwords;
my %wordTekno;
my %wordTravel;
my %words;
my %total; 
my $process=1;
my $ngrams = Lingua::EN::Ngram->new;

# load stopword and get all clean file
load_stopwords(\%stopwords);
my @files = `find $DIRECTORY/*.html`;

print "\nOn process...\n";
# get single file
foreach my $file(@files){
    # read file
    my $xml = `cat $file`;

    # get all text article
    my @texts = (
        get_text($xml,"title"),
        get_text($xml,"sec1"),
        get_text($xml,"sec2"),
        get_text($xml,"sec3"),
        get_text($xml,"sec4"),
        get_text($xml,"sec5")
    );

    # read title, top, middle, and bottom text
    foreach my $text (@texts){
        $ngrams->text($text);
        # ngram 1, 2, and 3
        foreach my $i (1 .. 3){
            my $grams = $ngrams->ngram($i);
            # load all ngram 1/2/3
            foreach my $gram ( sort { $$grams{ $b } <=> $$grams{ $a } } keys %$grams ) {
                my $next = 1;
                # check stopword or punctuation
                foreach my $word (split / /,$gram){
                    if ($stopwords{ $word } or $word =~ /['"Â,.?!:;()\-]|\s/){
                        $next = 0;
                        last;
                    }
                }

                next if($next == 0);
                # count word result and maximum freq word by gram
                word_count($file,$gram,$$grams{ $gram },$i); #namefile, word, freq word, and ngram
                total_word_gram($file,$i,$$grams{ $gram }); #namefile, ngram, and freq word
            }
        }
    }

    if ($process % 1000 == 0){
        print "\nProcess done : $process\n";
    }
    $process++;
}

my @THRESHOLDS = (0.45,0.5);
# open file to output dictionary tekno and travel
open OUTTEKNO45, ">$PATH/Kamus_Tekno45.txt" or die "Can't Open File...";
open OUTTRAVEL45, ">$PATH/Kamus_Travel45.txt" or die "Can't Open File...";
open OUTTEKNO50, ">$PATH/Kamus_Tekno50.txt" or die "Can't Open File...";
open OUTTRAVEL50, ">$PATH/Kamus_Travel50.txt" or die "Can't Open File...";
binmode(OUTTEKNO45, "encoding(UTF-8)");
binmode(OUTTEKNO50, "encoding(UTF-8)");
binmode(OUTTRAVEL45, "encoding(UTF-8)");
binmode(OUTTRAVEL50, "encoding(UTF-8)");

print "\nOutput Dictionary to Tekno or Travel Category...\n";

# load all word between tekno and travel category
foreach my $word (sort { $words{ $b } <=> $words{ $a } } keys %words){
    foreach my $THRESHOLD (@THRESHOLDS){
        next if(dont_have($word,$THRESHOLD,$words{$word}));#word, threshold, and ngram
        # formula to normalize freq
        my $formula = formulas($words{$word},$word); #ngram, and word
        my $nfreqTekno = $wordTekno{$word}/$total{"tekno-".$words{$word}};
        my $nfreqTravel = $wordTravel{$word}/$total{"travel-".$words{$word}};

        # check threshold
        if($formula <= $THRESHOLD && $nfreqTekno > $nfreqTravel){
            threshold_clasification("tekno-".$words{$word},$THRESHOLD,$word); #hash ngram, threshold, and word
        }elsif($formula <= $THRESHOLD){
            threshold_clasification("travel-".$words{$word},$THRESHOLD,$word); #hash ngram, threshold, and word
        }
    }
}
close OUTTEKNO45;
close OUTTRAVEL45;
close OUTTEKNO50;
close OUTTRAVEL50;
print "\nDone...\n";

# method for check word in hash tekno and travel or not
sub dont_have{
    my $word = $_[0];
    my $THRESHOLD = $_[1];
    my $ngram = $_[2];

    if(!exists($wordTekno{$word})){
        threshold_clasification("travel-$ngram",$THRESHOLD,$word); #hash ngram, threshold, and word
    }elsif(!exists($wordTravel{$word})){
        threshold_clasification("tekno-$ngram",$THRESHOLD,$word); #hash ngram, threshold, and word
    }elsif(exists($wordTekno{$word}) && exists($wordTravel{$word})){
        return 0 eq 1;
    }
    return 0 eq 0;
}

# method for logic formula
sub formulas{
    my $ngram = $_[0];
    my $word = $_[1];
    my $nfreqTekno = $wordTekno{$word}/$total{"tekno-$ngram"};
    my $nfreqTravel = $wordTravel{$word}/$total{"travel-$ngram"};

    if($nfreqTekno > $nfreqTravel){
        return $nfreqTravel / $nfreqTekno;
    }else{
        return $nfreqTekno / $nfreqTravel;
    }
}

# method for get text in xml file
sub get_text{
    my $text = $_[0];
    my $regex = $_[1];

    if($text =~ /<$regex>(.*?)<\/$regex>/){
        return $1;
    }
}

# method for get all stopword in stopword.txt
sub load_stopwords{
    my $hashref = shift;
    open IN, "< $PATH/stopword.txt" or die "Cannot Open File!!!";
    while (<IN>)
    {
        chomp;
        if(!defined $$hashref{$_})
        {
            $$hashref{$_} = 1;
        }
    }  
}

# method for count freq word in tekno or travel
sub word_count{
    my $file = $_[0];
    my $gram = $_[1];
    my $count = $_[2];
    my $ngram = $_[3];

    $gram =~ s/\s+$//g;
    chomp($gram);
    if(!exists($words{$gram})){
        $words{$gram}=$ngram;
    }
    if(!exists($wordTekno{$gram}) and $file =~ /tekno/){
        $wordTekno{$gram}=$count;
    }elsif(!exists($wordTravel{$gram}) and $file =~ /travel/){
        $wordTravel{$gram}=$count;
    }elsif($file =~ /tekno/){
        $wordTekno{$gram}+=$count;
    }elsif($file =~ /travel/){
        $wordTravel{$gram}+=$count;
    }
}

# count maximum word by ngram
sub total_word_gram{
    my $file = $_[0];
    my $ngram = $_[1];
    my $count = $_[2];

    if($file=~/tekno/ && !exists($total{"tekno-".$ngram})){
        $total{"tekno-".$ngram}=$count;
    }elsif($file=~/travel/ && !exists($total{"travel-".$ngram})){
        $total{"travel-".$ngram}=$count;
    }elsif($file =~ /tekno/){        
        $total{"tekno-".$ngram}+=$count;
    }elsif($file =~ /travel/){
        $total{"travel-".$ngram}+=$count;
    }        
}

# check threshold print
sub threshold_clasification{
    my $hash_ngram = $_[0];
    my $THRESHOLD = $_[1];
    my $word = $_[2];
    
    if($THRESHOLD == 0.5 && $hash_ngram =~ /tekno/){
        print OUTTEKNO50 lc($word).":".$wordTekno{$word}.":".sprintf("%.8f",($wordTekno{$word}/$total{$hash_ngram}))."\n";
    }elsif($THRESHOLD == 0.5 && $hash_ngram =~ /travel/){
        print OUTTRAVEL50 lc($word).":".$wordTravel{$word}.":".sprintf("%.8f",($wordTravel{$word}/$total{$hash_ngram}))."\n";
    }elsif($hash_ngram =~ /tekno/){
        print OUTTEKNO45 lc($word).":".$wordTekno{$word}.":".sprintf("%.8f",($wordTekno{$word}/$total{$hash_ngram}))."\n";
    }else{
        print OUTTRAVEL45 lc($word).":".$wordTravel{$word}.":".sprintf("%.8f",($wordTravel{$word}/$total{$hash_ngram}))."\n";
    }
}