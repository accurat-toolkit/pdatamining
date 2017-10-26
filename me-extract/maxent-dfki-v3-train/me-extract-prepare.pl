#!/usr/bin/perl -w

# Creates the training/testing files (negative and positive) for the MaxEnt Parallel Sentence Extractor from DFKI (ver. 3)
# It needs the training/testing corpora with one sentence per line, source/target in different files, same number of lines.
#
# (C) RACAI 2012, Radu ION.
#
# ver 0.1, 15-Jan-2012, Radu ION: created.

use strict;
use warnings;
use utf8;

sub readCorpus( $$ );

if ( scalar( @ARGV ) != 5 ) {
	die( "me-extract-prepare.pl <src lang: en, ro, de, ...> <trg lang: en, ro, de, ...> <train|test> <.src line corpus> <.trg line corpus>\n" );
}

my( $SRCLANG ) = $ARGV[0];
my( $TRGLANG ) = $ARGV[1];

if ( $SRCLANG !~ /^(?:en|ro|de|lt|lv|hr|el|et|sl)$/ ) {
	warn( "me-extract-prepare::main: SOURCE LANGUAGE is not an ACCURAT language!\n" );
}
elsif ( $TRGLANG !~ /^(?:en|ro|de|lt|lv|hr|el|et|sl)$/ ) {
	warn( "me-extract-prepare::main: TARGET LANGUAGE is not an ACCURAT language!\n" );
}
elsif ( $SRCLANG eq $TRGLANG ) {
	die( "me-extract-prepare::main: SOURCE LANGUAGE equals TARGET LANGUAGE !\n" );
}

my( $CTYPE ) = $ARGV[2];

if ( $CTYPE ne "train" && $CTYPE ne "test" ) {
	die( "me-extract-prepare::main: CORPUS TYPE must be 'train' or 'test' !\n" );
}

my( @srccorpus ) = readCorpus( $ARGV[3], $SRCLANG );
my( @trgcorpus ) = readCorpus( $ARGV[4], $TRGLANG );

if ( scalar( @srccorpus ) != scalar( @trgcorpus ) ) {
	die( "me-extract-prepare::main: SOURCE CORPUS and TARGET CORPUS do not have the same number of lines !\n" );
}

open( POSSRC, ">", $CTYPE . ".pos." . $SRCLANG ) or die( "me-extract-prepare::main: cannot open file '" . $CTYPE . ".pos." . $SRCLANG . "' !\n" );
binmode( POSSRC, ":utf8" );

foreach my $line ( @srccorpus ) {
	print( POSSRC $line . "\n" );
}

close( POSSRC );

open( POSTRG, ">", $CTYPE . ".pos." . $TRGLANG ) or die( "me-extract-prepare::main: cannot open file '" . $CTYPE . ".pos." . $TRGLANG . "' !\n" );
binmode( POSTRG, ":utf8" );

foreach my $line ( @trgcorpus ) {
	print( POSTRG $line . "\n" );
}

close( POSTRG );

#Scramble the SRC/TRG corpora to get the negative examples.
my( @srccorpusrand ) = ();
my( @trgcorpusrand ) = ();

foreach my $l ( reverse( @srccorpus ) ) {
	if ( rand() < 0.5 ) {
		push( @srccorpusrand, $l );
	}
	else {
		unshift( @srccorpusrand, $l );
	}
}

foreach my $l ( @trgcorpus ) {
	if ( rand() < 0.5 ) {
		push( @trgcorpusrand, $l );
	}
	else {
		unshift( @trgcorpusrand, $l );
	}
}

open( NEGSRC, ">", $CTYPE . ".neg." . $SRCLANG ) or die( "me-extract-prepare::main: cannot open file '" . $CTYPE . ".neg." . $SRCLANG . "' !\n" );
binmode( NEGSRC, ":utf8" );

foreach my $line ( @srccorpusrand ) {
	print( NEGSRC $line . "\n" );
}

close( NEGSRC );

open( NEGTRG, ">", $CTYPE . ".neg." . $TRGLANG ) or die( "me-extract-prepare::main: cannot open file '" . $CTYPE . ".neg." . $TRGLANG . "' !\n" );
binmode( NEGTRG, ":utf8" );

foreach my $line ( @trgcorpusrand ) {
	print( NEGTRG $line . "\n" );
}

close( NEGTRG );

#End Main.

sub readCorpus( $$ ) {
	my( @corpus ) = ();
	my( $lcnt ) = 0;
	
	open( COR, "<", $_[0] ) or die( "me-extract-prepare::readCorpus[$_[1]]: cannot open file '$_[0]' !\n" );
	binmode( COR, ":utf8" );
	
	while ( my $line = <COR> ) {
		$lcnt++;
		
		warn( "me-extract-prepare::readCorpus[$_[1]]: read $lcnt lines...\n" ) if ( $lcnt % 1000 == 0 );
		
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		
		my( @toks ) = split( /\s+/, $line );
		
		foreach my $t ( @toks ) {
			$t = lc( $t );
			$t =~ s/^([^\/]+)\/.+$/$1/;
			$t =~ s/&abreve;/ă/g;
			$t =~ s/&tcedil;/ţ/g;
			$t =~ s/&scedil;/ş/g;
			$t =~ s/&acirc;/â/g;
			$t =~ s/&icirc;/î/g;
		}
		
		my( $newline ) = join( " ", @toks );
		
		#Left glue
		$newline =~ s/\s([,.;:%!?\$])(?:\s|$)/$1 /g;
		#Right glue
		$newline =~ s/(?:\s|^)([\{\(\[])\s/ $1/g;
		#Left glue
		$newline =~ s/\s([\}\)\]])(?:\s|$)/$1 /g;
		$newline =~ s/([^\s])-\s/$1-/g;
		$newline =~ s/\s-([^\s])/-$1/g;
		$newline =~ s/_/ /g;
		$newline =~ s/\sn\'t\s/n't /g;
		$newline =~ s/\s(\'ll|\'m|\'ve|\'re|\'s)\s/$1 /g;
		$newline =~ s/^\s+//;
		$newline =~ s/\s+$//;
		
		push( @corpus, $newline );
	}
	
	close( COR );
	return @corpus;
}
