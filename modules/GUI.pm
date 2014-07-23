#!/usr/bin/perl

package GUI;

require Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/init_gui/;

use strict;
use warnings;
use Gtk2 qw/-init -threads-init/;
use Glib qw/TRUE FALSE/;
use utf8;
use lib '.';
use Scan;

our $use_p = 0;
our $p = '127.0.0.1';
our $pp = 8118;

sub uniq {
	return keys %{{ map { $_ => 1 } @_ }}; 
}

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


sub proxy_dialog {

	my $window = Gtk2::Dialog->new('Proxy Settings',
		undef,
		[qw/modal destroy-with-parent/],
		'gtk-ok'     => 'ok'
	);

	$window->set_size_request(400,200);

	my $vbox = $window->vbox;

	my $frame = Gtk2::Frame->new(" Proxy Settings: ");
	$frame->modify_bg('normal',Gtk2::Gdk::Color->parse('#000000'));
	my $layout = Gtk2::Layout->new();
	$frame->add($layout);

	my $check_bt = Gtk2::CheckButton->new(" Use HTTP Proxy ");
	my $entry = Gtk2::Entry->new();
	my $entry2 = Gtk2::Entry->new();

	$entry->set_text($p);
	$entry2->set_text($pp);

	$entry2->set_size_request(60,-1);

	$layout->put($check_bt,10,10);
	$layout->put(Gtk2::Label->new("Domain/IP:"), 20,50);
	$layout->put(Gtk2::Label->new("Port:"), 250,50);
	$layout->put($entry,30,80);
	$layout->put($entry2,260,80);
	$check_bt->set_active(TRUE) if($use_p == 1);
	$entry->set_state('insensitive') if($use_p == 0);
	$entry2->set_state('insensitive') if($use_p == 0);

	$check_bt->signal_connect(toggled => sub {
		if($check_bt->get_active){
			$entry->set_state('normal'); 
			$entry->set_sensitive(TRUE);
			$entry2->set_state('normal');
			$entry2->set_sensitive(TRUE);
			$use_p = 1;
		} else {
			$entry->set_state('insensitive');
			$entry2->set_state('insensitive');
			$use_p = 0;
		}

	});

	$window->signal_connect(response => sub {
		if($check_bt->get_active){
			$use_p = 1;
			$p = $entry->get_text();
			$pp = $entry2->get_text();
			
		} else {
			$use_p = 0;
		}

		if(open(PROXY,'<./conf/proxy.cfg')){
			my @lol = <PROXY>;
			my $cont = join '',@lol;
			if($use_p == 0){
				$cont =~ s/<use>(.*?)<\/use>/<use>FALSE<\/use>/g;
			} else {
				$cont =~ s/<use>(.*?)<\/use>/<use>TRUE<\/use>/g;
			}
			$cont =~ s/<host>(.*?)<\/host>/<host>$p<\/host>/g;
			$cont =~ s/<port>(.*?)<\/port>/<port>$pp<\/port>/g;
			close(PROXY);
			if(open(PROXY,'>./conf/proxy.cfg')){
				print PROXY $cont;
			}
		}
	
		$window->destroy;
		Gtk2->main_quit;
	});

	$vbox->pack_start($frame,TRUE,TRUE,0);

	$window->signal_connect('delete-event'=> sub {Gtk2->main_quit()});
	$window->set_position('center-always');



	$window->show_all();
	Gtk2->main();
}

sub About_box {
	my $ab = Gtk2::AboutDialog->new();
	$ab->set_version('1.0');
	$ab->set_program_name ('Bing Multi Dork Scanner');
	$ab->set_authors ('MMxM');
	$ab->set_comments("Bing Multi Dork Scanner\nhttp://hc0der.blogspot.com");
	$ab->set_license('Creative Commons');
	$ab->run;
	$ab->destroy;
}


sub clear {
	shift;
	my $text_box = shift;
	$text_box->get_buffer()->set_text('');
}

sub load_list {
	shift;
	my $ref = shift;
	my @arr = @{$ref};
	my($m_window,$tw)= @arr;
	my $file_choose = Gtk2::FileChooserDialog->new (
		'Save Result',
		$m_window,
		'open',
		'gtk-cancel' => 'cancel',
		'gtk-ok' => 'ok'
	);
	
	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("Text Files");
	$filter->add_mime_type("text/plain");
	$file_choose->add_filter($filter);
	my $file_name;
	if($file_choose->run eq 'ok'){
		$file_name = $file_choose->get_filename if($file_choose->get_filename);
	} else {
		$file_choose->destroy;
		return;
	}
	
	if(!$file_name){
		$file_choose->destroy;
		return;
	}
	
	if(open(FILE,'<'.$file_name)){
		&clear(undef,$tw);
		my @con = <FILE>;
		$tw->get_buffer()->insert_at_cursor(join '',@con);
		&show_message_dialog( $file_choose, 'info' , scalar(@con)." Words Loaded" , 'ok');
	} else {
		my $err = $!;
		utf8::encode($err);
		&show_message_dialog( $file_choose, 'error' , "Failed to open file:\n".$err , 'ok');
	}
	$file_choose->destroy;
}

sub show_message_dialog {

my ($parent,$icon,$text,$button_type) = @_;
my $dialog = Gtk2::MessageDialog->new_with_markup ($parent,
	[qw/modal destroy-with-parent/],
	$icon,
	$button_type,
	sprintf "$text");
	my $retval = $dialog->run;
	$dialog->destroy;
	return $retval;
}

sub save {
	shift;
	my $tw2 = shift;
	my $file_choose = Gtk2::FileChooserDialog->new (
		'Save Result',
		undef,
		'save',
		'gtk-cancel' => 'cancel',
		'gtk-ok' => 'ok'
	);

	$file_choose->set_current_name('urls.txt');
	my $output_name;

	if($file_choose->run eq 'ok'){
		$output_name = $file_choose->get_filename;
	}

	$file_choose->destroy;

	if (defined $output_name){
		if (-f $output_name){
			my $overwrite = show_message_dialog( undef,
				'question',
				'Overwrite existing file:'."<b>\n$output_name</b>",
				'yes-no'
			);
			return  if ($overwrite eq 'no');
		}
	} else {
		return;
	}

	my $buffer_x = $tw2->get_buffer();
	my $start = $buffer_x->get_start_iter();
	my $end = $buffer_x->get_end_iter();
	my $h = $buffer_x->get_text($start,$end,FALSE);
	my @con_box = split("\n",$h);
	my @clear_box = &uniq(@con_box);
	my $err;
	my $fh; 
	my $hh = join("\n",@clear_box);
	if(open($fh, '>'.$output_name)){
		print $fh $hh;
		print $fh "\n";
		close($fh);
		show_message_dialog( undef,
		'info' , "Results saved successfully !!!\n".(scalar(@con_box)-scalar(@clear_box))." repeated URL's removed\n".scalar(@clear_box)." URL's Saved" , 'ok');
		return;
	}
	
	$err = $!;
	utf8::decode($err);
	show_message_dialog( undef, 'error' , "Failed to save file !!!\n\n'$err'" , 'close');
	return;	

	
}


sub init_gui {
	open(A,'<./conf/gtkrc');
	my @con = <A>;
	my $aaa = join '',@con;
	Gtk2::Rc->parse_string($aaa);

	my $color = Gtk2::Gdk::Color->new(0,0,0);


	my $window = new Gtk2::Window();
	$window->set_position('center-always');
	$window->set_title('[ Bing Scan v1.0 ]');
	$window->set_size_request(632,398);
	$window->set_resizable(FALSE);
	$window->signal_connect('delete-event' => sub { Gtk2->main_quit; });


	my $menubar = Gtk2::MenuBar->new();
	my $item1 = Gtk2::MenuItem->new('Help');
	my $item3 = Gtk2::MenuItem->new('Config');
	my $submenu = Gtk2::Menu->new();
	my $submenu1 = Gtk2::Menu->new();
	my $item2 = Gtk2::MenuItem->new('About');
	my $item4 = Gtk2::MenuItem->new('Proxy');

	$submenu->append($item2);
	$submenu1->append($item4);

	$item1->set_submenu($submenu);
	$item3->set_submenu($submenu1);
	$menubar->append($item3);
	$menubar->append($item1);

	$item2->signal_connect('activate' => \&About_box);
	$item4->signal_connect('activate' => \&proxy_dialog);


	my $statusb = Gtk2::Statusbar->new();
	my $context_id = $statusb->get_context_id("Progress");
	$statusb->push($context_id,"Status: Stop");

	my $mlb = Gtk2::Layout->new();
	my $sw = new Gtk2::ScrolledWindow();
	$sw->set_policy('automatic','automatic');


	my $button1 = Gtk2::Button->new("Start Searching");
	$button1->set_size_request(207,30);

	my $img = Gtk2::Image->new_from_file('./bk.png');

	my $ly = Gtk2::Layout->new();

	my $frame1 = Gtk2::Frame->new(" Dork_List ");
	$frame1->set_size_request(349,161);

	my $button2 = Gtk2::Button->new("Load List");
	$button2->set_size_request(104,29);

	my $button3 = Gtk2::Button->new("Clear List");
	$button3->set_size_request(104,29);



	my $scroll1 = Gtk2::ScrolledWindow->new();
	$scroll1->set_size_request(210,130);
	$scroll1->set_policy('automatic','automatic');
	$scroll1->set_shadow_type('in');
	my $tview1 = Gtk2::TextView->new();

	$scroll1->add($tview1);

	$button3->signal_connect(clicked => \&clear , $tview1);
	$button2->signal_connect(clicked => \&load_list, [ $window, $tview1 ]);
	$ly->put($scroll1,127,2);
	$ly->put($button3,13,45);
	$ly->put($button2,13,12);

	$frame1->add($ly);

	my $frame2 = Gtk2::Frame->new(" Result: ");
	$frame2->set_size_request(622,158);

	my $ly2 = Gtk2::Layout->new();

	my $button4 = Gtk2::Button->new("Save List");
	$button4->set_size_request(184,29);

	my $button5 = Gtk2::Button->new("Clear List");
	$button5->set_size_request(184,29);


	my $lb1 = Gtk2::Label->new("URL's Extracted:");

	my $lbnb = Gtk2::Label->new("00000");
	$lbnb->set_size_request(72,20);

	my $sw2 = Gtk2::ScrolledWindow->new();
	$sw2->set_size_request(405,130);
	$sw2->set_policy('automatic','automatic');
	$sw2->set_shadow_type('in');

	my $tw2 = Gtk2::TextView->new();
	$tw2->set_editable(FALSE);
	$sw2->add($tw2);

	$button1->signal_connect(clicked => \&starter, [ $tview1,$statusb,$tw2,$lbnb,$sw2 ]);
	$button5->signal_connect(clicked => \&clear , $tw2);
	$button4->signal_connect(clicked => \&save, $tw2);

	$ly2->put($sw2,6,2);
	$ly2->put($lbnb,524,20);
	$ly2->put($lb1,423,20);
	$ly2->put($button4,423,70);
	$ly2->put($button5,423,102);

	$frame2->add($ly2);
	$frame1->modify_bg('normal',$color);
	$frame2->modify_bg('normal',$color);

	$mlb->put($frame1,269,15);
	$mlb->put($frame2,5,188);
	$mlb->put($img,31,32);
	$mlb->put($button1,27,126);

	$sw->add($mlb);
	my $vbox = new Gtk2::VBox(FALSE,0);

	$vbox->pack_start($menubar, FALSE, FALSE, 0);
	$vbox->pack_start($sw, TRUE,TRUE, 0);
	$vbox->pack_start($statusb, FALSE,FALSE,0);

	$window->add($vbox);
	$window->show_all;
	Gtk2::Gdk::Threads->enter;
	Gtk2->main;
	Gtk2::Gdk::Threads->leave;

}

1;
