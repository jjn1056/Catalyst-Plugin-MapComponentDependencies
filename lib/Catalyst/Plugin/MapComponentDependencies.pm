package Catalyst::Plugin::MapComponentDependencies;

use Moose::Role;

requires 'config_for';

sub map_dependency {
  my ($app, $name, $args) = @_;
  die "Component $name exists" if
    $app->config->{'Plugin::MapComponentDependencies'}->{map_dependencies}->{$name};
  $app->config->{'Plugin::MapComponentDependencies'}->{map_dependencies}->{$name} = $args;
}
 
sub map_dependencies {
  my $app = shift;
  while(@_) {
    $app->map_dependency(shift, shift);
  }
}
around 'config_for', sub {
  my ($orig, $app_or_ctx, @args) = @_;
  my $config = $app_or_ctx->$orig(@args);

  return $config;
};

1;

=head1 NAME

Catalyst::Plugin::MapComponentDependencies - Allow components to depend on other components

=head1 SYNOPSIS

    package MyApp;
    
    use Catalyst qw/MapComponentDependencies/;

    MyApp->map_dependencies(
      'Model::Foo' => {
        bar => 'Model::Bar',
        baz => sub {
          my ($app_or_ctx, $component_name) = @_;
          return ...;
        },
      },
    );

    MyApp->config(
      'Model::Foo' => { another_param => 'value' }
    )

    MyApp->setup;

During setup when 'Model::Foo' is created it will get all three key / value pairs
send to ->new.

=head1 DESCRIPTION

Sometimes you would like a L<Catalyst> component to depend on the value of an
existing component.  Since components are resolved during application setup (or
at request time, in the cause of a component that does ACCEPT_CONTEXT) you cannot
specify this dependency mapping in the 'normal' L<Catalyst> configuration hash.

This plugin, which requires a recent L<Catalyst> of version 5.90090+, allows you to
define components which depend on each other.  You can also set the value of an
initial argument to the value of a coderef, for added dynamic flexibility.

=head1 METHODS

This plugin defines the following methods

=head2 map_dependencies

Example:

    MyApp->map_dependencies(
      'Model::AnotherModel' => { aaa => 'Model::Foo' },
      'Model::Foo' => {
        bar => 'Model::Bar',
        baz => sub {
          my ($app_or_ctx, $component_name) = @_;
          return ...;
        },
      },
    );

Maps a list of components and dependencies

=head1 map_dependency

Maps a single component to a hashref of dependencies.

=head1 CONFIGURATION

This plugin defines the configuration namespace 'Plugin::MapComponentDependencies'
and defines the following keys:

=head2 map_dependencies

A Hashref where the key is a target component and the value is a hashref of arguments
that will be sent to it during initializion.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::InjectionHelpers>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
