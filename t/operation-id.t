use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use File::Spec::Functions;
use Mojolicious::Lite;
use lib 't/lib';

plugin Swagger2 => {url => 'data://main/petstore.json'};
app->routes->namespaces(['MyApp::Controller']);

my $t = Test::Mojo->new;

$MyApp::Controller::Pet::RES = [{id => 123, name => 'kit-cat'}];
$t->get_ok('/api/pets')->status_is(200)->json_is('/0/id', 123)->json_is('/0/name', 'kit-cat');

$MyApp::Controller::Pet::RES = {name => 'kit-cat'};
$t->post_ok('/api/pets/42')->status_is(200)->json_is('/id', 42)->json_is('/name', 'kit-cat');

for (qw( FS FileSystem Incoming )) {
  eval "package MyApp::Controller::$_; use Mojo::Base 'Mojolicious::Controller';1" or die $@;
}

is_ca('methodFS' => [qw(MyApp::Controller::FS method)], "simple camelCase");

is_ca('methodNameFS' => [qw(MyApp::Controller::FS method_name)], "camelCase with multi-word method name");

is_ca('underscore_methodFS' => [qw(MyApp::Controller::FS underscore_method)], "method name with underscore");

for my $operator (qw( By From For In Of To With)) {
  is_ca(
    "methodName${operator}FileSystem" => [qw(MyApp::Controller::FileSystem method_name)],
    "operator $operator is ignored"
  );
}

is_ca('addInodeInFS' => [qw(MyApp::Controller::FS addInode)], "method name contains operator 'In'");

is_ca('findInIncoming' => [qw(MyApp::Controller::Incoming find)], "controller name contains operator 'In'");

is_ca(
  'addInodeInIncoming' => [qw(MyApp::Controller::Incoming addInode)],
  "controller and method names contain operator 'In'"
);

done_testing;

sub is_ca {
  my ($op, $expected, $name) = @_;

  my $c = $t->app->controller_class->new(app => $t->app);
  my $m = Mojolicious::Plugin::Swagger2->can('_find_action');
  my $e = $m->($c, {operationId => $op}, my $r = {});
  diag $e if $e and $ENV{SWAGGER2_DEBUG};
  is_deeply [@$r{qw( controller action )}] => $expected, $name ? "$op: $name" : $op;
}

__DATA__
@@ petstore.json
{
  "swagger": "2.0",
  "info": { "version": "1.0.0", "title": "Swagger Petstore" },
  "basePath": "/api",
  "paths": {
    "/pets": {
      "get": {
        "operationId": "listPets",
        "responses": {
          "200": { "description": "pet response", "schema": { "type": "array", "items": { "$ref": "#/definitions/Pet" } } }
        }
      }
    },
    "/pets/{petId}": {
      "post": {
        "operationId": "showPetById",
        "parameters": [
          {
            "name": "petId",
            "in": "path",
            "required": true,
            "description": "The id of the pet to receive",
            "type": "integer"
          }
        ],
        "responses": {
          "200": { "description": "Expected response to a valid request", "schema": { "$ref": "#/definitions/Pet" } }
        }
      }
    }
  },
  "definitions": {
    "Pet": {
      "required": [ "id", "name" ],
      "properties": {
        "id": { "type": "integer", "format": "int64" },
        "name": { "type": "string" },
        "tag": { "type": "string" }
      }
    }
  }
}
