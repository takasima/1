# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::L10N::fr;

use strict;
use base 'MT::Community::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Community.pack/config.yaml
	q{Increase reader engagement - deploy features to your website that make it easier for your readers to engage with your content and your company.} => q{Accroître l'implication du lecteur - en ajoutant des fonctionnalités sur votre site web rendant facile pour vos lecteurs de s'impliquer sur le contenu et votre société.},
	'Create forums where users can post topics and responses to topics.' => 'Créer des forums où les utilisateurs peuvent publier des sujets et des réponses aux sujets.',
	'Users followed by [_1]' => 'Utilisateurs suivis par [_1]',
	'Users following [_1]' => 'Utilisateurs qui suivent [_1]',
	'Community' => 'Communauté',
	'Sanitize' => 'Nettoyer',
	'Followed by' => 'Suivit par',
	'Followers' => 'Suiveurs',
	'Following' => 'Suit',
	'Pending Entries' => 'Notes en attente',
	'Spam Entries' => 'Notes indésirables',
	'Recently Scored' => 'Noté récemment',
	'Recent Submissions' => 'Soumissions récentes',
	'Most Popular Entries' => 'Notes les plus populaires',
	'Registrations' => 'Inscriptions',
	'Login Form' => 'Formulaire d\'identification',
	'Registration Form' => 'Formulaire d\'enregistrement',
	'Registration Confirmation' => 'Confirmation d\'enregistrement',
	'Profile Error' => 'Erreur de profil',
	'Profile View' => 'Vue du profil',
	'Profile Edit Form' => 'Formulaire de modification du profil',
	'Profile Feed' => 'Flux du profil',
	'New Password Form' => 'Nouveau formulaire de mot de passe',
	'New Password Reset Form' => 'Nouveau formulaire de réinitialisation du mot de passe',
	'Form Field' => 'Champ de formulaire',
	'Status Message' => 'Message de statut',
	'Simple Header' => 'Tête de page simple',
	'Simple Footer' => 'Pied de page simple',
	'Header' => 'Entête',
	'Footer' => 'Pied',
	'GlobalJavaScript' => 'GlobalJavaScript',
	'Email verification' => 'Vérification email',
	'Registration notification' => 'Notification enregistrement',
	'New entry notification' => 'Notification de nouvelle note',
	'Community Styles' => 'Styles communautés',
	'A collection of styles compatible with Community themes.' => 'Une collection de styles compatibles avec les thèmes communauté',
	'Community Blog' => 'Blog de la communauté',
	'Atom ' => 'Atom',
	'Entry Response' => 'Réponse à la note',
	'Displays error, pending or confirmation message when submitting an entry.' => 'Afficher les erreurs et les messages de confirmation quand une note est écrite.',
	'Entry Detail' => 'Détails de la note',
	'Entry Metadata' => 'Metadonnées de la note',
	'Page Detail' => 'Détails de la page',
	'Entry Form' => 'Formulaire de note',
	'Content Navigation' => 'Navigation du contenu',
	'Activity Widgets' => 'Widgets d\'activité',
	'Archive Widgets' => 'Widgets d\'archive',
	'Community Forum' => 'Forum de la communauté',
	'Entry Feed' => 'Flux de la note',
	'Displays error, pending or confirmation message when submitting a entry.' => 'Affiche les messages d\'erreur, de validation et de confirmation quand une nouvelle note est créée.',
	'Popular Entry' => 'Note populaire',
	'Entry Table' => 'Tableau de note',
	'Content Header' => 'Entête du contenu',
	'Category Groups' => 'Groupes de catégorie',
	'Default Widgets' => 'Widgets par défaut',

## addons/Community.pack/lib/MT/App/Community.pm
	'No login form template defined' => 'Aucun formulaire d\'identification de défini',
	'Before you can sign in, you must authenticate your email address. <a href="[_1]">Click here</a> to resend the verification email.' => 'Avant de pouvoir vous identifier, vous devez confirmer votre adresse email. <a href="[_1]">Cliquez ici</a> pour envoyer à nouveau l\'email de vérification.',
	'You are trying to redirect to external resources: [_1]' => 'Vous tentez une redirection vers des ressources externes: [_1]', # Translate - New
	'(No email address)' => '(pas d\'adresse e-mail)',
	'User \'[_1]\' (ID:[_2]) has been successfully registered.' => 'L\'utilisateur \'[_1]\' (ID:[_2]) a été enregistré avec succès.',
	'Thanks for the confirmation.  Please sign in.' => 'Merci pour la confirmation. Identifiez-vous.',
	'[_1] registered to Movable Type.' => '[_1] s\'est enregistré(e) à Movable Type.',
	'Login required' => 'Authentification obligatoire',
	'Title or Content is required.' => 'Le titre ou le contenu est requis.',
	'System template entry_response not found in blog: [_1]' => 'Gabarit système entry_response introuvable dans le blog: [_1]',
	'New entry \'[_1]\' added to the blog \'[_2]\'' => 'Nouvelle note \'[_1]\' ajoutée sur le blog \'[_2]\'',
	'Id or Username is required' => 'Id ou identifiant obligatoire',
	'Unknown user' => 'Utilisateur inconnu',
	'Password should not include your Username' => 'Le mot de passe ne doit pas être composé de votre nom d\'utilisateur',
	'Recent Entries from [_1]' => 'Notes récentes de [_1]',
	'Responses to Comments from [_1]' => 'Réponses aux commentaires de [_1]',
	'Actions from [_1]' => 'Actions de [_1]',

## addons/Community.pack/lib/MT/Community/CMS.pm

## addons/Community.pack/lib/MT/Community/Tags.pm
	'You used an \'[_1]\' tag outside of the block of MTIfEntryRecommended; perhaps you mistakenly placed it outside of an \'MTIfEntryRecommended\' container?' => 'Vous avez utilisé un tag \'[_1]\' en dehors d\'un bloc de MTIfEntryRecommended; Peut-être l\'avez-vous placé par erreur en dehors d\'un conteneur \'MTIfEntryRecommended\' ?',
	'Click here to recommend' => 'Cliquer ici pour recommander',
	'Click here to follow' => 'Cliquer ici pour suivre',
	'Click here to leave' => 'Cliquer ici pour quitter',

## addons/Community.pack/php/function.mtentryrecommendvotelink.php

## addons/Community.pack/templates/blog/about_this_page.mtml
	'This page contains a single entry by <a href="[_1]">[_2]</a> published on <em>[_3]</em>.' => 'Cette page contient une unique note de <a href="[_1]">[_2]</a> publiée le <em>[_3]</em>.',

## addons/Community.pack/templates/blog/archive_index.mtml

## addons/Community.pack/templates/blog/archive_widgets_group.mtml

## addons/Community.pack/templates/blog/categories.mtml

## addons/Community.pack/templates/blog/category_archive_list.mtml

## addons/Community.pack/templates/blog/comment_detail.mtml

## addons/Community.pack/templates/blog/comment_form.mtml

## addons/Community.pack/templates/blog/comment_listing.mtml

## addons/Community.pack/templates/blog/comment_preview.mtml
	'Comment on [_1]' => 'Commentaire sur [_1]',

## addons/Community.pack/templates/blog/comment_response.mtml

## addons/Community.pack/templates/blog/comments.mtml
	'The data in #comments-content will be replaced by some calls to paginate script' => 'Les données dans #comments-content seront remplacées par des appels aux scripts de pagination.',

## addons/Community.pack/templates/blog/content_nav.mtml
	'Blog Home' => 'Accueil du blog',

## addons/Community.pack/templates/blog/current_category_monthly_archive_list.mtml

## addons/Community.pack/templates/blog/dynamic_error.mtml

## addons/Community.pack/templates/blog/entry_create.mtml

## addons/Community.pack/templates/blog/entry_detail.mtml

## addons/Community.pack/templates/blog/entry_form.mtml
	'In order to create an entry on this blog you must first register.' => 'Avant de créer une note sur ce blog, vous devez vous enregistrer.',
	q{You don't have permission to post.} => q{Vous n'avez pas la permission de poster.},
	'Sign in to create an entry.' => 'Identifiez-vous pour créer une note.',
	'Select Category...' => 'Sélectionner la catégorie...',

## addons/Community.pack/templates/blog/entry_listing.mtml
	'Recently by <em>[_1]</em>' => 'Récemment par <em>[_1]</em>',

## addons/Community.pack/templates/blog/entry_metadata.mtml
	'Vote' => 'Vote',
	'Votes' => 'Votes',

## addons/Community.pack/templates/blog/entry.mtml

## addons/Community.pack/templates/blog/entry_response.mtml
	q{Thank you for posting an entry.} => q{Merci d'avoir posté votre message.},
	'Entry Pending' => 'Message en attente',
	q{Your entry has been received and held for approval by the blog owner.} => q{Votre message a été reçu et est en attente d'approbation par le propriétaire du blog.},
	'Entry Posted' => 'Message posté',
	'Your entry has been posted.' => 'Votre message a bien été posté.',
	'Your entry has been received.' => 'Votre message a été reçu.',
	q{Return to the <a href="[_1]">blog's main index</a>.} => q{Retour à la <a href="[_1]">page principale du blog</a>.},

## addons/Community.pack/templates/blog/entry_summary.mtml

## addons/Community.pack/templates/blog/javascript.mtml

## addons/Community.pack/templates/blog/main_index.mtml

## addons/Community.pack/templates/blog/main_index_widgets_group.mtml

## addons/Community.pack/templates/blog/monthly_archive_list.mtml

## addons/Community.pack/templates/blog/openid.mtml

## addons/Community.pack/templates/blog/page.mtml

## addons/Community.pack/templates/blog/pages_list.mtml

## addons/Community.pack/templates/blog/powered_by.mtml

## addons/Community.pack/templates/blog/recent_assets.mtml

## addons/Community.pack/templates/blog/recent_comments.mtml
	'<a href="[_1]">[_2] commented on [_3]</a>: [_4]' => '<a href="[_1]">[_2] a commenté sur [_3]</a> : [_4]',

## addons/Community.pack/templates/blog/recent_entries.mtml

## addons/Community.pack/templates/blog/search.mtml

## addons/Community.pack/templates/blog/search_results.mtml

## addons/Community.pack/templates/blog/sidebar.mtml
	q{Activity Widgets} => q{Widgets d'activité},
	q{Archive Widgets} => q{Widgets d'archive},

## addons/Community.pack/templates/blog/syndication.mtml

## addons/Community.pack/templates/blog/tag_cloud.mtml

## addons/Community.pack/templates/blog/tags.mtml

## addons/Community.pack/templates/blog/trackbacks.mtml

## addons/Community.pack/templates/forum/archive_index.mtml

## addons/Community.pack/templates/forum/category_groups.mtml
	'Forum Groups' => 'Groupes de forums',
	'Last Topic: [_1] by [_2] on [_3]' => 'Dernier sujet: [_1] par [_2] sur [_3]',
	'Be the first to <a href="[_1]">post a topic in this forum</a>' => 'Soyez le premier à <a href="[_1]">créer un sujet dans ce forum</a>',

## addons/Community.pack/templates/forum/comment_detail.mtml
	'[_1] replied to <a href="[_2]">[_3]</a>' => '[_1] a répondu à <a href="[_2]">[_3]</a>',

## addons/Community.pack/templates/forum/comment_form.mtml
	'Add a Reply' => 'Ajouter une Réponse',

## addons/Community.pack/templates/forum/comment_listing.mtml

## addons/Community.pack/templates/forum/comment_preview.mtml
	'Reply to [_1]' => 'Répondre à [_1]',
	'Previewing your Reply' => 'Prévisualiser votre réponse',

## addons/Community.pack/templates/forum/comment_response.mtml
	'Reply Submitted' => 'Réponse envoyée',
	'Your reply has been accepted.' => 'Votre réponse a été acceptée.',
	'Thank you for replying.' => 'Merci pour votre réponse.',
	q{Your reply has been received and held for approval by the forum administrator.} => q{Votre réponse a bien été reçue et est en attente d'approbation par un administrateur du forum.},
	q{Reply Submission Error} => q{Erreur lors de l'envoi de la réponse},
	q{Your reply submission failed for the following reasons: [_1]} => q{L'envoi de la réponse a échoué pour les raisons suivantes : [_1]},
	q{Return to the <a href="[_1]">original topic</a>.} => q{Retour au <a href="[_1]">sujet d'origine</a>.},

## addons/Community.pack/templates/forum/comments.mtml
	'1 Reply' => '1 Réponse',
	'# Replies' => '# Réponses',
	'No Replies' => 'Pas de Réponses',

## addons/Community.pack/templates/forum/content_header.mtml
	'Start Topic' => 'Débuter un sujet',

## addons/Community.pack/templates/forum/content_nav.mtml

## addons/Community.pack/templates/forum/dynamic_error.mtml

## addons/Community.pack/templates/forum/entry_create.mtml
	'Start a Topic' => 'Créer un nouveau sujet',

## addons/Community.pack/templates/forum/entry_detail.mtml

## addons/Community.pack/templates/forum/entry_form.mtml
	'Topic' => 'Sujet',
	'Select Forum...' => 'Sélectionner un forum...',
	'Forum' => 'Forum',

## addons/Community.pack/templates/forum/entry_listing.mtml

## addons/Community.pack/templates/forum/entry_metadata.mtml

## addons/Community.pack/templates/forum/entry.mtml

## addons/Community.pack/templates/forum/entry_popular.mtml
	'Popular topics' => 'Sujets populaires',
	'Last Reply' => 'Dernière réponse',
	'Permalink to this Reply' => 'Lien permanent vers cette réponse',
	'By [_1]' => 'Par [_1]',

## addons/Community.pack/templates/forum/entry_response.mtml
	q{Thank you for posting a new topic to the forums.} => q{Merci d'avoir créé un nouveau sujet dans le forum.},
	'Topic Pending' => 'Sujet en attente',
	'The topic you posted has been received and held for approval by the forum administrators.' => 'Le sujet que vous avez créé a bien été reçu et il est en attente de validation par les administrateurs du forum.',
	'Topic Posted' => 'Sujet posté',
	'The topic you posted has been received and published. Thank you for your submission.' => 'Le sujet que vous avez créé a bien été reçu et publié. Merci.',
	q{Return to the <a href="[_1]">forum's homepage</a>.} => q{Retour à la <a href="[_1]">page d'accueil du forum</a>.},

## addons/Community.pack/templates/forum/entry_summary.mtml

## addons/Community.pack/templates/forum/entry_table.mtml
	'Recent Topics' => 'Sujets récents',
	'Replies' => 'Réponses',
	'Closed' => 'Fermé',
	'Post the first topic in this forum.' => 'Créez le premier sujet de ce forum.',

## addons/Community.pack/templates/forum/javascript.mtml
	'Thanks for signing in,' => 'Merci de vous être identifié,',
	'. Now you can reply to this topic.' => '. Maintenant vous pouvez répondre à ce sujet.',
	q{You do not have permission to comment on this blog.} => q{Vous n'avez pas la permission de commenter sur ce blog.},
	' to reply to this topic.' => ' pour répondre à ce sujet.',
	' to reply to this topic,' => ' pour répondre à ce sujet,',
	'or ' => 'ou ',
	'reply anonymously.' => 'répondre anonymement.',

## addons/Community.pack/templates/forum/main_index.mtml
	'Forum Home' => 'Accueil du forum',

## addons/Community.pack/templates/forum/openid.mtml

## addons/Community.pack/templates/forum/page.mtml

## addons/Community.pack/templates/forum/search_results.mtml
	'Topics matching &ldquo;[_1]&rdquo;' => 'Sujets correspondants à &ldquo;[_1]&rdquo;',
	'Topics tagged &ldquo;[_1]&rdquo;' => 'Sujets taggués &ldquo;[_1]&rdquo;',
	'Topics' => 'Sujets',

## addons/Community.pack/templates/forum/sidebar.mtml

## addons/Community.pack/templates/forum/syndication.mtml
	'All Forums' => 'Tous les forums',
	'[_1] Forum' => 'Forum [_1]',

## addons/Community.pack/templates/global/email_verification_email.mtml
	'Thank you registering for an account to [_1].' => 'Merci de créer un compte sur [_1].',
	'For your own security and to prevent fraud, we ask that you please confirm your account and email address before continuing. Once confirmed you will immediately be allowed to sign in to [_1].' => 'Pour votre propre sécurité et pour prévenir la fraude, nous vous demandons de confirmer votre compte et adresse email avant de continuer. Une fois confirmés vous serez immédiatement autorisé à vous identifier sur [_1].',
	q{If you did not make this request, or you don't want to register for an account to [_1], then no further action is required.} => q{Si vous n'avez pas fait cette demande, ou que vous ne souhaitez pas créer un compte sur [_1], alors aucune action n'est nécessaire.},

## addons/Community.pack/templates/global/footer.mtml

## addons/Community.pack/templates/global/header.mtml
	'Blog Description' => 'Description du blog',

## addons/Community.pack/templates/global/javascript.mtml

## addons/Community.pack/templates/global/login_form_module.mtml
	'Logged in as <a href="[_1]">[_2]</a>' => 'Identifié comme <a href="[_1]">[_2]</a>',
	'Logout' => 'Déconnexion',
	'Hello [_1]' => 'Bonjour [_1]',
	'Forgot Password' => 'Mot de passe oublié?',
	'Sign up' => 'Enregistrez-vous',

## addons/Community.pack/templates/global/login_form.mtml
	'Not a member?&nbsp;&nbsp;<a href="[_1]">Sign Up</a>!' => 'Pas encore membre?&nbsp;&nbsp;<a href="[_1]">Enregistrez-vous</a>!',

## addons/Community.pack/templates/global/navigation.mtml

## addons/Community.pack/templates/global/new_entry_email.mtml
	q{A new entry '[_1]([_2])' has been posted on your blog [_3].} => q{Une nouvelle note '[_1]([_2])' a été postée sur votre blog [_3].},
	q{Author name: [_1]} => q{Nom de l'auteur: [_1]},
	q{Author nickname: [_1]} => q{Surnom de l'auteur: [_1]},
	'Title: [_1]' => 'Titre: [_1]',
	'Edit entry:' => 'Modifier la note:',

## addons/Community.pack/templates/global/new_password.mtml

## addons/Community.pack/templates/global/new_password_reset_form.mtml
	'Go Back (x)' => 'Retour (x)',

## addons/Community.pack/templates/global/profile_edit_form.mtml
	'Go <a href="[_1]">back to the previous page</a> or <a href="[_2]">view your profile</a>.' => 'Retourner à  <a href="[_1]">la page précédente</a> ou <a href="[_2]">voir votre profil</a>.',

## addons/Community.pack/templates/global/profile_error.mtml
	'ERROR MSG HERE' => 'MSG ERREUR ICI',
	'Go Back' => 'Retour',

## addons/Community.pack/templates/global/profile_feed.mtml
	'Posted [_1] to [_2]' => 'A posté [_1] sur [_2]',
	'Commented on [_1] in [_2]' => 'A commenté sur [_1] dans [_2]',
	'Voted on [_1] in [_2]' => 'A voté sur [_1] dans [_2]',
	'[_1] voted on <a href="[_2]">[_3]</a> in [_4]' => '[_1] a voté sur <a href="[_2]">[_3]</a> dans [_4]',

## addons/Community.pack/templates/global/profile_view.mtml
	q{User Profile} => q{Profil de l'utilisateur},
	'Recent Actions from [_1]' => 'Actions récentes de [_1]',
	'You are following [_1].' => 'Vous suivez [_1]',
	'Unfollow' => 'Ne plus suivre',
	'Follow' => 'Suivre',
	'You are followed by [_1].' => 'Vous êtes suivi par [_1].',
	q{You are not followed by [_1].} => q{Vous n'êtes pas suivi par [_1].},
	'Website:' => 'Site Web:',
	'Recent Actions' => 'Actions récentes',
	'Comment Threads' => 'Fils de discussion',
	'Commented on [_1]' => 'A commenté sur [_1]',
	'Favorited [_1] on [_2]' => 'A mis comme favori [_1] dans [_2]',
	q{No recent actions.} => q{Plus d'actions récentes.},
	'[_1] commented on ' => '[_1] a commenté sur',
	'No responses to comments.' => 'Pas de réponse aux commentaires.',
	'Not following anyone' => 'Ne suit personne',
	q{Not being followed} => q{N'est pas suivi},

## addons/Community.pack/templates/global/register_confirmation.mtml
	q{Authentication Email Sent} => q{Email d'authentification envoyé},
	'Profile Created' => 'Profil créé',

## addons/Community.pack/templates/global/register_form.mtml

## addons/Community.pack/templates/global/register_notification_email.mtml

## addons/Community.pack/templates/global/search.mtml

## addons/Community.pack/templates/global/signin.mtml
	'You are signed in as <a href="[_1]">[_2]</a>' => 'Vous êtes identifié(e) comme étant <a href="[_1]">[_2]</a>',
	'You are signed in as [_1]' => 'Vous êtes identifié(e) comme étant [_1]',
	'Edit profile' => 'Editer le profil',
	'Not a member? <a href="[_1]">Register</a>' => 'Pas encore membre? <a href="[_1]">Enregistrez-vous</a>',

## addons/Community.pack/tmpl/cfg_community_prefs.tmpl
	'Community Settings' => 'Réglages de la communauté',
	'Anonymous Recommendation' => 'Recommandation anonyme',
	q{Check to allow anonymous users (users not logged in) to recommend discussion.  IP address is recorded and used to identify each user.} => q{Cocher pour autoriser les utilisateurs anonymes (non identifiés) à recommander une discussion. L'adresse IP est enregistrée et utilisée pour identifier chaque utilisateur.},
	'Allow anonymous user to recommend' => 'Autoriser un utilisateur anonyme à recommander',
	'Junk Filter' => 'Filtre de spam',
	'If enabled, all moderated entries will be filtered by Junk Filter.' => 'Si activé, toutes les notes modérées seront filtrés par le filtre de spam',
	'Save changes to blog (s)' => 'Sauvegarder les modifications du blog (s)',

## addons/Community.pack/tmpl/widget/blog_stats_registration.mtml
	'Recent Registrations' => 'Inscriptions récentes',
	q{default userpic} => q{Image de l'utilisateur par défaut},
	'You have [quant,_1,registration,registrations] from [_2]' => 'Vous avez [quant,_1,création de compte,créations de compte] sur [_2]',

## addons/Community.pack/tmpl/widget/most_popular_entries.mtml
	q{There are no popular entries.} => q{Il n'y a pas de notes populaires.},

## addons/Community.pack/tmpl/widget/recently_scored.mtml
	q{There are no recently favorited entries.} => q{Il n'y a pas de notes favorites récentes.},

## addons/Community.pack/tmpl/widget/recent_submissions.mtml

);

1;
