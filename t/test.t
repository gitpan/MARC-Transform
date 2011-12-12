#!/usr/bin/perl
use Data::Compare;
use strict;
use warnings;
use lib qw( lib ../lib );
use Cwd;
use YAML;
use Test::More 'no_plan';
BEGIN {
    use_ok( 'MARC::Transform' );
}

sub recordtostring {
	my ($record) = @_;
	my $string="";
	my $finalstring=$record->leader;
	my %tag_names = map( { $$_{_tag} => 1 } $record->fields);
	my @order = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
	foreach my $tag(sort({ $a cmp $b } keys(%tag_names)))
	{
		my @fields=$record->field($tag);
		foreach my $field(@fields)
		{
			$string.="|#f#|$tag:";
			if ($field->is_control_field())
			{
				$string.=$field->data();
			}
			else
			{
				$string.=$field->indicator(1);
				$string.=$field->indicator(2);
				foreach my $key (@order)
				{
					foreach my $subfield (sort({ $a cmp $b } $field->subfield($key)))
					{
						$string.="|$key:".$subfield;
					}
				}
			}
		}
	}
	my @arec = split(/\|#f#\|/,$string);#warn Data::Dumper::Dumper @arec;
	foreach my $tempstring (sort({ $a cmp $b } @arec))
	{
		$finalstring.="||$tempstring";
	}
	return $finalstring;
}

my $thisabsolutepath = getcwd."/".$0;
$thisabsolutepath=~s/\/test.t$//;
#test 1
my $record1a = MARC::Record->new();
$record1a->leader('optionnal leader');
$record1a->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content' ));
$record1a->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8b' ));
$record1a->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8a' ));
$record1a->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'a' => 'foao', 'b' => '1', 'b' => 'baoar', 'c' => 'big') );
$record1a->insert_fields_ordered( MARC::Field->new( '501', '', '', 'c' => '1') );
$record1a->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'I want "$"') );
$record1a->insert_fields_ordered( MARC::Field->new( '106', '', '', 'a' => 'VaLuE') );
$record1a->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'fee', 'a' => 'babar') );
$record1a->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'zut', 'a' => 'sisi') );
$record1a->insert_fields_ordered( MARC::Field->new( '604', '', '', 'a' => 'foo', 'a' => 'foo', 'b' => 'bar', 'c' => 'truc') );
$record1a->insert_fields_ordered( MARC::Field->new( '401', '', '', 'a' => 'afooa') );
$record1a->insert_fields_ordered( MARC::Field->new( '402', '1', '', 'a' => 'a402a1') );
$record1a->insert_fields_ordered( MARC::Field->new( '402', '', '2', 'a' => 'a402a2') );
my $record1b = MARC::Record->new();
$record1b->leader('optionnal leader');
$record1b->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content' ));
$record1b->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8b' ));
$record1b->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8a' ));
$record1b->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'a' => 'foao', 'b' => '1', 'b' => 'baoar', 'c' => 'big') );
$record1b->insert_fields_ordered( MARC::Field->new( '501', '', '', 'c' => '1') );
$record1b->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'I want "$"') );
$record1b->insert_fields_ordered( MARC::Field->new( '106', '', '', 'a' => 'VaLuE') );
$record1b->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'fee', 'a' => 'babar') );
$record1b->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'zut', 'a' => 'sisi') );
$record1b->insert_fields_ordered( MARC::Field->new( '604', '', '', 'a' => 'foo', 'a' => 'foo', 'b' => 'bar', 'c' => 'truc') );
$record1b->insert_fields_ordered( MARC::Field->new( '401', '', '', 'a' => 'afooa') );
$record1b->insert_fields_ordered( MARC::Field->new( '402', '1', '', 'a' => 'a402a1') );
$record1b->insert_fields_ordered( MARC::Field->new( '402', '', '2', 'a' => 'a402a2') );
#print "--init record--\n". $record1->as_formatted;
my $yaml1 = '---
condition : $f501a eq "foo"
create :
 f502a : this is the value of a subfield of a new 502 field
---
condition : $f401a=~/foo/
create :
 b : new value of the 401 conditions field
 f600 :
  a : 
   - first a subfield of this new 600 field
   - second a subfield of this new 600 field
  b : the 600b value
execute : \&reencodeRecordtoUtf8()
---
condition : $f502a eq "I want #_dbquote_##_dollars_##_dbquote_#"
create :
 f605a : "#_dbquote_#$f502a#_dbquote_# contain a #_dollars_# sign"
---
-
 condition : $f501a =~/foo/ and $f503a =~/bar/
 forceupdate :
  $f503b : mandatory b in condition\'s field
  f005_ : mandatory 005
  f006_ : \&return_record_encoding()
  f700 :
   a : the a subfield of this mandatory 700 field
   b : \&sub1("$f503a")
 forceupdatefirst :
  $f501b : update only the first b in condition\'s field 501
-
 condition : $f501a =~/foo/
 execute : \&warnfoo("f501a contain foo")
-
 subs : >
    sub return_record_encoding { $record->encoding(); }
    sub sub1 { my $string = shift;$string =~ s/a/e/g;return $string; }
    sub warnfoo { my $string = shift;warn $string; }
---
-
 condition : $f501b2 eq "o"
 update :
  c : updated value of all c in condition\'s field
  f504a : updated value of all 504a if exists
  f604 :
   b : \&LUT("$this")
   c : \&LUT("NY","cities")
 updatefirst :
  f604a : update only the first a in 604
-
 condition : $f501c eq "1"
 delete : $f501
-
 LUT :
   1 : first
   2 : second
   bar : openbar
---
delete :
 - f401a
 - f005
---
condition : $ldr2 eq "t"
execute : \&SetRecordToLowerCase($record)
---
condition : $f008_ eq "controlfield_content8b"
duplicatefield :
 - $f008 > f007
 - f402 > f602
delete : f402
---
global_subs: >
    sub reencodeRecordtoUtf8 {
        $record->encoding( \'UTF-8\' );
    }
    sub warnfee {
        my $string = shift;warn $string;
    }
global_LUT:
 cities:
  NY : New York
  SF : San Fransisco
 numbers:
  1 : one
  2 : two
';
$record1a = MARC::Transform->new($record1a,$yaml1);
$record1b = MARC::Transform->new($record1b,$yaml1);
#print "\n--transformed record--\n". $record1b->as_formatted ."\n";
my $v1aa=YAML::Dump recordtostring($record1a);
my $v1ba=YAML::Dump recordtostring($record1b);
my $v1b=YAML::Dump 'optionnalaleader||||006:UTF-8||007:controlfield_content8b||008:controlfield_content8a||008:controlfield_content8b||106:  |a:VaLuE||401:  |b:new value of the 401 conditions field||501:  |a:foao|a:foo|b:baoar|b:update only the first b in condition\'s field 501|c:updated value of all c in condition\'s field||501:  |c:1||502:  |a:I want "$"||502:  |a:this is the value of a subfield of a new 502 field||503:  |a:babar|a:fee|b:mandatory b in condition\'s field||504:  |a:updated value of all 504a if exists|a:updated value of all 504a if exists||600:  |a:first a subfield of this new 600 field|a:second a subfield of this new 600 field|b:the 600b value||602: 2|a:a402a2||602:1 |a:a402a1||604:  |a:foo|a:update only the first a in 604|b:openbar|c:New York||605:  |a:"I want "$"" contain a $ sign||700:  |a:the a subfield of this mandatory 700 field|b:beber';
ok(Compare($v1aa.$v1ba,$v1b.$v1b))
    or diag(Dump $v1aa.$v1ba);

#test 2
my $record2 = MARC::Record->new();
$record2->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo') );
#print "--init record--\n". $record2->as_formatted;
my $yaml2 = '---
condition : $f501a or $f502a
create :
 f600a : aaa
';
$record2 = MARC::Transform->new($record2,$yaml2);
#print "\n--transformed record--\n". $record2->as_formatted ."\n";
my $v2a=YAML::Dump recordtostring($record2);
my $v2b=YAML::Dump "                        ||||501:  |a:foo||600:  |a:aaa";
ok(Compare($v2a,$v2b))
    or diag(Dump $v2a);

#test 3
my $record3 = MARC::Record->new();
$record3->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
#print "--init record--\n". $record3->as_formatted;
my $yaml3 = '
---
condition : $f501a eq "foo"
create :
 f502a : value of a new 502a
update :
  $f501b : \&LUT("$this")
LUT :
 1 : first
 2 : second value in this LUT (LookUp Table)
---
delete : f501c
';
$record3 = MARC::Transform->new($record3,$yaml3);
#print "\n--transformed record--\n". $record3->as_formatted ."\n";
my $v3a=YAML::Dump recordtostring($record3);
my $v3b=YAML::Dump "                        ||||501:  |a:foo|b:first||502:  |a:value of a new 502a";
ok(Compare($v3a,$v3b))
    or diag(Dump $v3a);

#test 4
my $record4 = MARC::Record->new();
$record4->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
#print "--init record--\n". $record4->as_formatted;
my $yaml4 = '
---
condition : $f501a eq "foo"
create :
 b : new subfield value of the conditions field
 f502a : this is the value of a subfield of a new 502 field
 f502b : 
  - this is the first value of two \'b\' of another new 502
  - this is the 2nd value of two \'b\' of another new 502
 f600 :
  a : 
   - first a subfield of this new 600 field
   - second a subfield of this new 600 field
  b : the 600b value
';
$record4 = MARC::Transform->new($record4,$yaml4);
#print "\n--transformed record--\n". $record4->as_formatted ."\n";
my $v4a=YAML::Dump recordtostring($record4);
my $v4b=YAML::Dump "                        ||||501:  |a:foo|b:1|b:new subfield value of the conditions field|c:bar||502:  |a:this is the value of a subfield of a new 502 field||502:  |b:this is the 2nd value of two 'b' of another new 502|b:this is the first value of two 'b' of another new 502||600:  |a:first a subfield of this new 600 field|a:second a subfield of this new 600 field|b:the 600b value";
ok(Compare($v4a,$v4b))
    or diag(Dump $v4a);

#test 5
my $record5 = MARC::Record->new();
$record5->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record5->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record5->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record5->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'ccc1', 'c' => 'ccc2') );
#print "--init record--\n". $record5->as_formatted;
my $yaml5 = '
---
condition : $f502a eq "second a"
update :
 b : updated value of all \'b\' subfields in the condition field
 f502c : updated value of all \'c\' subfields into all \'502\' fields
 f501 :
  a : updated value of all \'a\' subfields into all \'501\' fields
  b : $f502a is the value of 502a conditionnal field
';
$record5 = MARC::Transform->new($record5,$yaml5);
#print "\n--transformed record--\n". $record5->as_formatted ."\n";
my $v5a=YAML::Dump recordtostring($record5);
my $v5b=YAML::Dump "                        ||||501:  |a:updated value of all 'a' subfields into all '501' fields|b:second a is the value of 502a conditionnal field|c:bar||502:  |a:first a|a:second a|b:updated value of all 'b' subfields in the condition field|c:updated value of all 'c' subfields into all '502' fields|c:updated value of all 'c' subfields into all '502' fields||502:  |a:poto||502:  |b:truc|c:updated value of all 'c' subfields into all '502' fields";
ok(Compare($v5a,$v5b))
    or diag(Dump $v5a);

#test 6
my $record6 = MARC::Record->new();
$record6->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record6->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record6->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record6->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'cc1', 'c' => 'cc2') );
#print "--init record--\n". $record6->as_formatted;
my $yaml6 = '
---
condition : $f502a eq "second a"
forceupdate :
 b : value of \'b\' subfields in the condition field
 f502c : value of \'502c\'
 f503 :
  a : value of \'503a\'
  b : $f502a is the value of 502a conditionnal field
';
$record6 = MARC::Transform->new($record6,$yaml6);
#print "\n--transformed record--\n". $record6->as_formatted ."\n";
my $v6a=YAML::Dump recordtostring($record6);
my $v6b=YAML::Dump "                        ||||501:  |a:foo|b:1|c:bar||502:  |a:first a|a:second a|b:value of 'b' subfields in the condition field|c:value of '502c'|c:value of '502c'||502:  |a:poto|c:value of '502c'||502:  |b:truc|c:value of '502c'||503:  |a:value of '503a'|b:second a is the value of 502a conditionnal field";
ok(Compare($v6a,$v6b))
    or diag(Dump $v6a);

#test 7
my $record7 = MARC::Record->new();
$record7->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record7->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record7->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record7->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'cc1', 'c' => 'cc2') );
#print "--init record--\n". $record7->as_formatted;
my $yaml7 = '
---
condition : $f502a eq "second a"
forceupdatefirst :
 b : value of \'b\' subfields in the condition field
 f502c : value of \'502c\'
 f503 :
  a : value of \'503a\'
  b : $f502a is the value of 502a conditionnal field
';
$record7 = MARC::Transform->new($record7,$yaml7);
#print "\n--transformed record--\n". $record7->as_formatted ."\n";
my $v7a=YAML::Dump recordtostring($record7);
my $v7b=YAML::Dump "                        ||||501:  |a:foo|b:1|c:bar||502:  |a:first a|a:second a|b:value of 'b' subfields in the condition field|c:cc2|c:value of '502c'||502:  |a:poto|c:value of '502c'||502:  |b:truc|c:value of '502c'||503:  |a:value of '503a'|b:second a is the value of 502a conditionnal field";
ok(Compare($v7a,$v7b))
    or diag(Dump $v7a);

#test 8
my $record8 = MARC::Record->new();
$record8->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'bar', 'b' => 'bb1', 'b' => 'bb2') );
$record8->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo') );
$record8->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'pata') );
$record8->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record8->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'pata') );
$record8->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'ata1', 'a' => 'ata2', 'b' => 'tbbt') );
#print "--init record--\n". $record8->as_formatted;
my $yaml8 = '
---
condition : $f501a eq "foo"
delete : $f501
---
condition : $f501a eq "bar"
delete : b
---
delete : f502
---
delete : 
 - f503
 - f504a
';
$record8 = MARC::Transform->new($record8,$yaml8);
#print "\n--transformed record--\n". $record8->as_formatted ."\n";
my $v8a=YAML::Dump recordtostring($record8);
my $v8b=YAML::Dump "                        ||||501:  |a:bar||504:  |b:tbbt";
ok(Compare($v8a,$v8b))
    or diag(Dump $v8a);

#test 9
my $record9 = MARC::Record->new();
$record9->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record9->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record9->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record9->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'ccc1', 'c' => 'ccc2') );
#print "--init record--\n". $record9->as_formatted;
my $yaml9 = '
---
condition : $f502a eq "second a"
updatefirst :
 b : updated value of first \'b\' subfields in the condition field
 f502c : updated value of first \'c\' subfields into all \'502\' fields
 f501 :
  a : updated value of first \'a\' subfields into all \'501\' fields
  b : $f502a is the value of 502a conditionnal field
';
$record9 = MARC::Transform->new($record9,$yaml9);
#print "\n--transformed record--\n". $record9->as_formatted ."\n";
my $v9a=YAML::Dump recordtostring($record9);
my $v9b=YAML::Dump "                        ||||501:  |a:updated value of first 'a' subfields into all '501' fields|b:second a is the value of 502a conditionnal field|c:bar||502:  |a:first a|a:second a|b:updated value of first 'b' subfields in the condition field|c:ccc2|c:updated value of first 'c' subfields into all '502' fields||502:  |a:poto||502:  |b:truc|c:updated value of first 'c' subfields into all '502' fields";
ok(Compare($v9a,$v9b))
    or diag(Dump $v9a);

#test 10
my $record10 = MARC::Record->new();
$record10->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content1' ));
$record10->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content2' ));
$record10->insert_fields_ordered( MARC::Field->new( '501', '1', '2', 'a' => 'bar', 'b' => 'bb1', 'b' => 'bb2') );
$record10->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo') );
#print "--init record--\n". $record10->as_formatted;
my $yaml10 = '
---
condition : $f501a eq "bar"
duplicatefield : $f501 > f400
---
condition : $f501a eq "foo"
duplicatefield : 
 - $f501 > f401
 - f005 > f006
';
$record10 = MARC::Transform->new($record10,$yaml10);
#print "\n--transformed record--\n". $record10->as_formatted ."\n";
my $v10a=YAML::Dump recordtostring($record10);
my $v10b=YAML::Dump "                        ||||005:controlfield_content1||005:controlfield_content2||006:controlfield_content1||006:controlfield_content2||400:12|a:bar|b:bb1|b:bb2||401:  |a:foo||501:  |a:foo||501:12|a:bar|b:bb1|b:bb2";
ok(Compare($v10a,$v10b))
    or diag(Dump $v10a);

#test 11
my $record11 = MARC::Record->new();
$record11->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => 'boo', 'd' => 'doo') );
#print "--init record--\n". $record11->as_formatted;
my $yaml11 = '
---
-
 condition : $f501a eq "foo"
 create : 
  c : \&fromo2e("$f501a")
 update :
  d : the value of this 501d is $this
  b : \&fromo2e("$this")
-
 subs: >
    sub fromo2e { my $string=shift; $string =~ s/o/e/g; $string; }
';
$record11 = MARC::Transform->new($record11,$yaml11);
#print "\n--transformed record--\n". $record11->as_formatted ."\n";
my $v11a=YAML::Dump recordtostring($record11);
my $v11b=YAML::Dump "                        ||||501:  |a:foo|b:bee|c:fee|d:the value of this 501d is doo";
ok(Compare($v11a,$v11b))
    or diag(Dump $v11a);

#test 12
my $record12 = MARC::Record->new();
$record12->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '8/12/10', 'c' => 'boo', 'd' => '40,00') );
#print "--init record--\n". $record12->as_formatted;
my $yaml12 = '
---
-
 condition : $f501a eq "foo" and defined $f501d
 update :
  b : \&convertbaddate("$this")
  c : \&trim("$f501d")
-
 subs: >
    sub convertbaddate {
        #this function convert date like "21/2/98" to "1998-02-28"
        my $in = shift;
        if ($in =~/^(\d{1,2})\/(\d{1,2})\/(\d{2}).*/)
        {
            my $day=$1;
            my $month=$2;
            my $year=$3;
            if ($day=~m/^\d$/) {$day="0".$day;}
            if ($month=~m/^\d$/) {$month="0".$month;}
            if (int($year)>12)
            {$year="19".$year;}
            else {$year="20".$year;}
            return "$year-$month-$day";
        }
        else
        {
            return $in;
        }
    }
    
    sub trim {
        # This function removes ",00" at the end of a string
        my $in = shift;
        $in=~s/,00$//;
        return $in;
    }
';
$record12 = MARC::Transform->new($record12,$yaml12);
#print "\n--transformed record--\n". $record12->as_formatted ."\n";
my $v12a=YAML::Dump recordtostring($record12);
my $v12b=YAML::Dump "                        ||||501:  |a:foo|b:2010-12-08|c:40|d:40,00";
ok(Compare($v12a,$v12b))
    or diag(Dump $v12a);

#test 13
my $record13 = MARC::Record->new();
$record13->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => 'bar', 'c' => '40,00') );
#print "--init record--\n". $record13->as_formatted;
my $yaml13 = '
---
condition : $f501a eq "foo"
update :
 b : \&areturn_record_encoding()
 c : \&atrim("$this")
---
global_subs: >
 sub areturn_record_encoding {
     $record->encoding();
 }
 
 sub atrim {
     # This function removes ",00" at the end of a string
     my $in = shift;
     $in=~s/,00$//;
     return $in;
 }
';
$record13 = MARC::Transform->new($record13,$yaml13);
#print "\n--transformed record--\n". $record13->as_formatted ."\n";
my $v13a=YAML::Dump recordtostring($record13);
my $v13b=YAML::Dump "                        ||||501:  |a:foo|b:MARC-8|c:40";
ok(Compare($v13a,$v13b))
    or diag(Dump $v13a);

#test 14
my $record14 = MARC::Record->new();
$record14->insert_fields_ordered( MARC::Field->new( '501', '', '', 'b' => 'bar', 'c' => '1') );
#print "--init record--\n". $record14->as_formatted;
my $yaml14 = '
---
-
 condition : $f501b eq "bar"
 create :
  f604a : \&LUT("$f501b")
 update :
  c : \&LUT("$this")
-
 LUT :
  1 : first
  2 : second
  bar : openbar
';
$record14 = MARC::Transform->new($record14,$yaml14);
#print "\n--transformed record--\n". $record14->as_formatted ."\n";
my $v14a=YAML::Dump recordtostring($record14);
my $v14b=YAML::Dump "                        ||||501:  |b:bar|c:first||604:  |a:openbar";
ok(Compare($v14a,$v14b))
    or diag(Dump $v14a);

#test 15
my $record15 = MARC::Record->new();
$record15->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => '1', 'b' => 'foo', 'c' => 'SF') );
#print "--init record--\n". $record15->as_formatted;
my $yaml15 = '
---
-
 update :
  f501a : \&LUT("$this","numbers")
  f501b : \&LUT("$this","cities")
  f501c : \&LUT("$this","cities")
---
global_LUT:
 cities:
  NY : New York
  SF : San Fransisco
  TK : Tokyo
 numbers:
  1 : one
  2 : two
';
$record15 = MARC::Transform->new($record15,$yaml15);
#print "\n--transformed record--\n". $record15->as_formatted ."\n";
my $v15a=YAML::Dump recordtostring($record15);
my $v15b=YAML::Dump "                        ||||501:  |a:one|b:foo|c:San Fransisco";
ok(Compare($v15a,$v15b))
    or diag(Dump $v15a);

#test 16
my $record16 = MARC::Record->new();
$record16->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'I want "$"') );
#print "--init record--\n". $record16->as_formatted;
my $yaml16 = '
---
condition : $f501a eq "I want #_dbquote_##_dollars_##_dbquote_#"
create :
 f604a : "#_dbquote_#$f501a#_dbquote_# contain a #_dollars_# sign"
';
$record16 = MARC::Transform->new($record16,$yaml16);
#print "\n--transformed record--\n". $record16->as_formatted ."\n";
my $v16a=YAML::Dump recordtostring($record16);
my $v16b=YAML::Dump '                        ||||501:  |a:I want "$"||604:  |a:"I want "$"" contain a $ sign';
ok(Compare($v16a,$v16b))
    or diag(Dump $v16a);

#test 17
my $record17 = MARC::Record->new();
$record17->insert_fields_ordered( MARC::Field->new( '995', '', '', 'a' => '1', 'b' => 'foo', 'c' => 'SF') );
$record17->insert_fields_ordered( MARC::Field->new( '995', '', '', 'a' => '2', 'b' => 'foo', 'c' => 'SF') );
$record17->insert_fields_ordered( MARC::Field->new( '995', '', '', 'a' => '1', 'b' => 'foo', 'c' => 'SF') );
#print "--init record--\n". $record17->as_formatted;
my $yaml17 = '
---
condition : $f995a eq "2"
update :
 b : updated value of all \'b\' subfields in the condition field
 $f995a : 3
 f995c : updated
';
$record17 = MARC::Transform->new($record17,$yaml17);
#print "\n--transformed record--\n". $record17->as_formatted ."\n";
my $v17a=YAML::Dump recordtostring($record17);
my $v17b=YAML::Dump "                        ||||995:  |a:1|b:foo|c:updated||995:  |a:1|b:foo|c:updated||995:  |a:3|b:updated value of all 'b' subfields in the condition field|c:updated";
ok(Compare($v17a,$v17b))
    or diag(Dump $v17a);

#test 18
my $record18 = MARC::Record->new();
$record18->leader('optionnal leader');
$record18->insert_fields_ordered( MARC::Field->new( '500', '', '', 'a' => '0123456789abcd') );
#print "--init record--\n". $record18->as_formatted;
my $yaml18 = '
---
condition : $ldr6 eq "n" and $f500a11 eq "b"
create :
  f604a : ok
';
$record18 = MARC::Transform->new($record18,$yaml18);
#print "\n--transformed record--\n". $record18->as_formatted ."\n";
my $v18a=YAML::Dump recordtostring($record18);
my $v18b=YAML::Dump "optionnal leader||||500:  |a:0123456789abcd||604:  |a:ok";
ok(Compare($v18a,$v18b))
    or diag(Dump $v18a);
