#!/usr/bin/perl


package Scan;

require Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/starter/;
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use threads;
use threads::shared;
use LWP;
use URI::Escape;
use utf8;


my $check: shared = 0;

sub uniq {
	return keys %{{ map { $_ => 1 } @_ }}; 
}

sub starter {
	return if($check == 1);
	shift;
	my $ref = shift;
	my @arr = @{$ref};
	my($sb) = $arr[1];
	my $context_id = $sb->get_context_id("Progress");
	$check = 1;
	my $thr = threads->create(\&bing_scanner , $ref);
	return;
}


sub bing_scanner {
	my $reff = shift;
	my @arr1 = @{$reff};
	
	my ($tview1,$statusb,$tw2,$lbnb,$scroll)= @arr1;
	select(undef,undef,undef,0.25);

	my($use_p,$p,$pp);
	$use_p = 0;
	if(open(PROXY,'<./conf/proxy.cfg')){
	my @tmp = <PROXY>;
	my $config_proxy = join '',@tmp;
	if($config_proxy =~ /<use>(.*?)<\/use>/){
		if(lc($1) eq 'true'){
			$use_p = 1;
		}
	}
	
	if($config_proxy =~ /<host>(.*?)<\/host>/){
		$p = $1;
	}
	
	if($config_proxy =~ /<port>(.*?)<\/port>/){
		$pp = $1;
	}

	close(PROXY);

}
	
	
	my $ci = $statusb->get_context_id("Status");
	my $buffer_x = $tview1->get_buffer();
	my $start = $buffer_x->get_start_iter();
	my $end = $buffer_x->get_end_iter();
	my $h = $buffer_x->get_text($start,$end,FALSE);
	my $tot = 0;
	
	my @busca = grep { /\S/ } split(/\n/,$h);

	if(scalar(@busca) == 0){
		$check = 0;
		return;
	}
	
	my @nbusca = &uniq(@busca);
	
	my $req = new LWP::UserAgent;
	$req->agent('Mozilla/5.0 (X11; Linux i686; rv:14.0) Gecko/20100101 Firefox/14.0.1');
	$req->proxy('http','http://'.$p.':'.$pp) if($use_p == 1);

	foreach my $dork(@nbusca){
		utf8::decode($dork);
		Gtk2::Gdk::Threads->enter;
		$statusb->push($ci,"Status: Searching for $dork ...");
		Gtk2::Gdk::Threads->leave;
		for(my $i=1;$i<211;$i+=10){
			my $url = 'http://www.bing.com/search?q='.uri_unescape($dork).'&first='.$i.'&FORM=PERE';
			my $resp = $req->get($url);
			my $body = $resp->content;
			my @x = ($body =~ /(?<=<li class="b_algo"><h2><a href=["]).*?(?=["])/g);
			$tot += scalar(@x);
			my $tot_lead = sprintf("%05d",$tot);
			Gtk2::Gdk::Threads->enter;

			foreach(@x){
				$_ =~ s/&amp;/&/g;
				$tw2->get_buffer()->insert($tw2->get_buffer()->get_end_iter(),"$_\n");
			}

			$lbnb->set_text($tot_lead);
			my $ad = $tw2->get_vadjustment();
			$ad->set_value($ad->upper - $ad->page_size);
			$scroll->set_vadjustment( $ad );
			Gtk2::Gdk::Threads->leave;
		}
	}
	
	
	Gtk2::Gdk::Threads->enter;
	$statusb->push($ci,"Status: Stop");
	Gtk2::Gdk::Threads->leave;
	$check = 0;
}

1;
