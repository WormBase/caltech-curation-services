#!D:/PERL/bin/perl.exe

use DictyBaseConfig;
use dicty::Search::Ontology;
use CGI;
my $q = new CGI();

my $q = new CGI();
print $q->header;


if ( $q->param('ontologyname') ) {
   my @objs = dicty::Search::Ontology->Search_term_by_name_with_wildcard( -ONTOLOGY => "PATO", TERM_NAME => $q->param('ontologyname'));
   my @names = map { $q->li( { id      => $_->term_id,
                               onMouseover => 'set_ontology('.$_->term_id.')',
                               onClick => 'set_ontology('.$_->term_id.')' },$_->name() ) } @objs;

   if ( scalar @names == 0 ) {
      @names = ( $q->li( "NO RESULTS FOUND" ) );
   }
   print $q->ul( join("\n",@names) );
   exit;
}


if ( $q->param('ontologyid') ) {

my $cvterm = new dicty::CV::Term(-CVTERM_DBID => $q->param('ontologyid') );

my $type = new dicty::CV::Term(-NAME => "IS_A", -ONTOLOGY => $cvterm->ontology() );
my @types;
push(@types, $type);

   my @parents = $cvterm->get_parent_terms(@types);
   my @children = $cvterm->get_child_terms(@types);

   my $parents = join("<BR>", map{$_->name()} @parents);
   my $children = join("<BR>", map{$_->name()} @children);
   print $q->table(
            $q->TR( $q->td( {class=>'label'}, "Ontology")        .$q->td( {class=>'data'}, $cvterm->ontology->name() ) ).
            $q->TR( $q->td( {class=>'label'}, "Term name")        .$q->td( {class=>'data'}, $cvterm->name() ) ).
            $q->TR( $q->td( {class=>'label'}, "Identifier")  .$q->td( {class=>'data'}, $cvterm->identifier() )   ).
            $q->TR( $q->td( {class=>'label'}, "Definition")        .$q->td( {class=>'data'}, $cvterm->definition() ) ).
            $q->TR( $q->td( {class=>'label'}, "Is obsolete")  .$q->td( {class=>'data'}, $cvterm->is_obsolete() )).
            $q->TR( $q->td( {class=>'label'}, "Synonymns")  .$q->td( {class=>'data'}, $cvterm->get_synonyms() )).
            $q->TR( $q->td( {class=>'label'}, "Parent terms")  .$q->td( {class=>'data'}, "<BR>".$parents )).
            $q->TR( $q->td( {class=>'label'}, "Children terms")  .$q->td( {class=>'data'}, "<BR>".$children ))
   );
   exit;
}