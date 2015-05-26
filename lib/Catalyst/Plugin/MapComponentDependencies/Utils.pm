package Catalyst::Plugin::MapComponentDependencies::Utils;

use Scalar::Util 'blessed';
use Exporter 'import';
use Data::Visitor::Callback;

our @EXPORT_OK = (qw/FromModel FromView FromController FromComponent FromCode ConfigLoaderSubstitutions/);
our %EXPORT_TAGS = (All => \@EXPORT_OK, ALL => \@EXPORT_OK);

sub model_ns {  __PACKAGE__ .'::MODEL' }
sub view_ns {  __PACKAGE__ .'::VIEW' }
sub controller_ns {  __PACKAGE__ .'::CONTROLLER' }
sub component_ns {  __PACKAGE__ .'::COMPONENT' }
sub code_ns {  __PACKAGE__ .'::CODE' }

sub _is {
  my ($possible, $target_ns) = @_;
  return (defined($possible) and
    blessed($possible) and 
      $possible->isa($target_ns)) ?
        $$possible : 0;
}

sub is_model($) { return _is(shift, model_ns) }
sub is_view($) { return _is(shift, view_ns) }
sub is_controller($) { return _is(shift, controller_ns) }
sub is_component($) { return _is(shift, component_ns) }
sub is_code($) { return _is(shift, code_ns) }

sub FromModel($) { my $v = shift; return bless \$v, model_ns }
sub FromView($) { my $v = shift; return bless \$v, view_ns }
sub FromController($) { my $v = shift; return bless \$v, controller_ns }
sub FromComponent($) { my $v = shift; return bless \$v, component_ns }
sub FromCode(&) { my $v = shift; return bless \$v, code_ns }

sub _expand_config {
  my ($app_or_ctx, $component_name, $config) = @_;
  my $visitor_cb = sub {
    my ( $visitor, $data ) = @_;

    if(my $m = is_model $data ) { return $_ = $app_or_ctx->model($m) || die "$m is not a Model" }
    if(my $v = is_view $data ) { return $_ = $app_or_ctx->view($v) || die "$v is not a View" }
    if(my $c = is_controller $data ) { return $_ = $app_or_ctx->controller($c) || die "$c is not a Controller" }
    if(my $c = is_component $data ) { return $_ = $app_or_ctx->component($c) || die "$c is not a Component" }
    if(my $c = is_code $data ) { return $_ = $c->($app_or_ctx, $component_name, $config) }

    return $data;
  };

  Data::Visitor::Callback->new(visit => $visitor_cb)
    ->visit($config);
}

sub ConfigLoaderSubstitutions {
  return (
    FromModel => sub { my $c = shift; FromModel(@_) },
    FromView => sub { my $c = shift; FromView(@_) },
    FromController => sub { my $c = shift; FromController(@_) },
    FromComponent => sub { my $c = shift; FromComponent(@_) },
    FromCode => sub {
      my $c = shift;
      FromCode { eval shift };
    },
  );
}

1;

=head1 TITLE

Catalyst::Plugin::MapComponentDependencies::Utils - Utilities to integrate dependencies

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use Catalyst 'MapComponentDependencies;
    use Catalyst::Plugin::MapComponentDependencies::Utils ':All';

    MyApp->config(
      'Model::Bar' => { key => 'value' },
      'Model::Foo' => {
        bar => FromModel 'Bar',
        baz => FromCode {
          my ($app_or_ctx, $component_name) = @_;
          return ...;
        },
        another_param => 'value',
      },
    );

    MyApp->setup;

=head1 DESCRIPTION

Utility functions to streamline integration of dynamic dependencies into your
global L<Catalyst> configuration.

L<Catalyst::Plugin::MapComponentDependencies> offers a simple way to specify
configuration values for you components to be the value of other components
and to do so in a way that respects if your component does ACCEPT_CONTEXT.
We do this by providing a new namespace key in your configuration.  However
you may prefer a 'flatter' configuration.  These utility methods allow you to
'tag' a value in your configuration.  This leads to a more simple configuration
setup, but it has the downside in that you must either use a Perl configuration
(as in the SYNOPSIS example) or if you are using L<Catalyst::Plugin::ConfigLoader>
you can install additional configuration substitutions like so:

    use Catalyst::Plugin::MapComponentDependencies::Utils ':All';

    __PACKAGE__->config->{ 'Plugin::ConfigLoader' }
      ->{ substitutions } = { ConfigLoaderSubstitutions };

See L<Catalyst::Plugin::MapComponentDependencies> for other options to declare
your component dependencies if this approach does not appeal.

=head1 EXPORTS

This package exports the following functions

=head2 FromModel

Creates a dependency to the named model.

=head2 FromView

Creates a dependency to the named model.

=head2 FromController

Creates a dependency to the named controller.

=head2 FromCode

An anonymouse coderef that must return the expected dependency.

=head2 ConfigLoaderSubstitutions

Returns a Hash suitable for use as additional substitutions in
L<Catalyst::Plugin::ConfigLoader>.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::MapComponentDependencies>,
L<Catalyst::Plugin::ConfigLoader>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
