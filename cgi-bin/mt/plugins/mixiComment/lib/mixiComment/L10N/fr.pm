package mixiComment::L10N::fr;

use strict;
use base 'mixiComment::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

## plugins/mixiComment/lib/mixiComment/App.pm
    'mixi reported that you failed to login.  Try again.' =>
        'mixi n\'a pas réussi à vous identifier. Veuillez réessayer.',

## plugins/mixiComment/mixiComment.pl
    q{Allows commenters to sign in to Movable Type using their own mixi username and password via OpenID.}
        => q{Permet aux auteurs de commentaires de s'identifier sur Movable Type en utilisant leur nom d'utilisateur mixi via OpenID.},
    'mixi' => 'mixi',

## plugins/mixiComment/tmpl/config.tmpl
    q{A mixi ID has already been registered in this blog.  If you want to change the mixi ID for the blog, <a href="[_1]">click here</a> to sign in using your mixi account.  If you want all of the mixi users to comment to your blog (not only your my mixi users), click the reset button to remove the setting.}
        => q{Un ID mixi est déjà enregistré sur ce blog. Si vous souhaitez modifier l'ID mixi, <a href="[_1]">cliquez ici</a> pour vous identifier en utilisant votre compte mixi. Si vous souhaitez permettre à tous les utilisateurs mixi de commenter sur votre blog (et pas uniquement vos utilisateurs mixi), cliquez sur le bouton de réinitialisation pour retirer les paramètres.},
    'If you want to restrict comments only from your my mixi users, <a href="[_1]">click here</a> to sign in using your mixi account.'
        => 'Si vous souhaitez restreindre les commentaires à uniquement vos utilisateurs mixi, <a href="[_1]">cliquez ici</a> pour vous identifier en utilisant votre compte mixi.',

);

1;
