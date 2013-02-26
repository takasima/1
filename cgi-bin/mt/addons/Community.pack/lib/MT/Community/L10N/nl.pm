# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::L10N::nl;

use strict;
use base 'MT::Community::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## addons/Community.pack/config.yaml
	'Increase reader engagement - deploy features to your website that make it easier for your readers to engage with your content and your company.' => 'Verhoog de betrokkenheid van uw lezers - voeg opties toe aan uw website die het makkelijker maken voor uw lezers om betrokken te zijn bij uw inhoud en bedrijf.',
	'Create forums where users can post topics and responses to topics.' => 'Maak forums aan waar gebruikers onderwerpen kunnen aanmaken en antwoorden kunnen publiceren.',
	'Users followed by [_1]' => 'Gebruikers gevolgd door [_1]',
	'Users following [_1]' => 'Gebruikers die [_1] volgen',
	'Community' => 'Gemeenschap',
	'Sanitize' => 'Schoonmaakfilter',
	'Followed by' => 'Gevolgd door',
	'Followers' => 'Volgers',
	'Following' => 'Volgt',
	'Pending Entries' => 'Berichten in wachtrij',
	'Spam Entries' => 'Spamberichten',
	'Recently Scored' => 'Recent beoordeeld',
	'Recent Submissions' => 'Recente inzendingen',
	'Most Popular Entries' => 'Populairste berichten',
	'Registrations' => 'Registraties',
	'Login Form' => 'Aanmeldformulier',
	'Registration Form' => 'Registratieformulier',
	'Registration Confirmation' => 'Registratiebevestiging',
	'Profile Error' => 'Profielfout',
	'Profile View' => 'Profiel bekijken',
	'Profile Edit Form' => 'Bewerkingsformulier profiel',
	'Profile Feed' => 'Profielfeed',
	'New Password Form' => 'Formulier nieuw wachtwoord',
	'New Password Reset Form' => 'Formulier nieuw wachtwoord resetten',
	'Form Field' => 'Veld in formulier',
	'Status Message' => 'Statusboodschap',
	'Simple Header' => 'Eenvoudige hoofding',
	'Simple Footer' => 'Eenvoudige voettekst',
	'Header' => 'Hoofding',
	'Footer' => 'Voettekst',
	'GlobalJavaScript' => 'GlobaalJavaScript',
	'Email verification' => 'E-mail verificatie',
	'Registration notification' => 'Registratienotificatie',
	'New entry notification' => 'Notificatie nieuw bericht',
	'Community Styles' => 'Community stijlen',
	'A collection of styles compatible with Community themes.' => 'Een collectie stijlen compatibel met de Community thema\'s',
	'Community Blog' => 'Community-blog',
	'Atom ' => 'Atom',
	'Entry Response' => 'Antwoord op bericht',
	'Displays error, pending or confirmation message when submitting an entry.' => 'Toont foutboodschappen, \'even geduld\' berichten of bevestigingen bij het indienen van een bericht.',
	'Entry Detail' => 'Berichtdetails',
	'Entry Metadata' => 'Metadata bericht',
	'Page Detail' => 'Pagina detail',
	'Entry Form' => 'Berichtenformulier',
	'Content Navigation' => 'Navigatie inhoud',
	'Activity Widgets' => 'Activiteit widgets',
	'Archive Widgets' => 'Archiefwidgets',
	'Community Forum' => 'Community forum',
	'Entry Feed' => 'Berichtenfeed',
	'Displays error, pending or confirmation message when submitting a entry.' => 'Toont foutboodschappen, \'even geduld\' berichten of bevestigingen bij het indienen van een bericht.',
	'Popular Entry' => 'Populair bericht',
	'Entry Table' => 'Berichttabel',
	'Content Header' => 'Hoofding inhoud',
	'Category Groups' => 'Categoriegroepen',
	'Default Widgets' => 'Standaardwidgets',

## addons/Community.pack/lib/MT/App/Community.pm
	'No login form template defined' => 'Geen sjabloon gedefiniëerd voor het aanmeldformulier',
	'Before you can sign in, you must authenticate your email address. <a href="[_1]">Click here</a> to resend the verification email.' => 'Voor u kunt aanmelden, moet u eerst uw e-mail adres bevestigen. <a href="[_1]">Klik hier</a> om de verificatiemail opnieuw te versturen.',
	'You are trying to redirect to external resources: [_1]' => 'U probeert te verwijzen naar externe bronnen: [_1]', # Translate - New
	'(No email address)' => '(Geen e-mail adres)',
	'User \'[_1]\' (ID:[_2]) has been successfully registered.' => 'Gebruiker \'[_1]\' (ID:[_2]) werd met succes geregistreerd.',
	'Thanks for the confirmation.  Please sign in.' => 'Bedankt voor de bevestiging.  Gelieve u aan te melden.',
	'[_1] registered to Movable Type.' => '[_1] geregistreerd bij Movable Type',
	'Login required' => 'Aanmelden vereist',
	'Title or Content is required.' => 'Titel of inhoud is vereist.',
	'System template entry_response not found in blog: [_1]' => 'Systeemsjabloon entry_response niet gevonden voor blog: [_1]',
	'New entry \'[_1]\' added to the blog \'[_2]\'' => 'Nieuw bericht \'[_1]\' toegevoegd aan de blog \'[_2]\'',
	'Id or Username is required' => 'ID of gebruikersnaam is verplicht',
	'Unknown user' => 'Onbekende gebruiker',
	'Recent Entries from [_1]' => 'Recente berichten van [_1]',
	'Responses to Comments from [_1]' => 'Antwoorden op reacties van [_1]',
	'Actions from [_1]' => 'Acties van [_1]',

## addons/Community.pack/lib/MT/Community/CMS.pm

## addons/Community.pack/lib/MT/Community/Tags.pm
	'You used an \'[_1]\' tag outside of the block of MTIfEntryRecommended; perhaps you mistakenly placed it outside of an \'MTIfEntryRecommended\' container?' => 'U gebruikte een \'[_1]\' tag buiten een MTIfEntryRecommended blok; misschien heeft u die daar per ongeluk geplaatst?',
	'Click here to recommend' => 'Klik hier om aan te raden',
	'Click here to follow' => 'Hier klikken om te volgen',
	'Click here to leave' => 'Hier klikken om niet meer te volgen',

## addons/Community.pack/php/function.mtentryrecommendvotelink.php

## addons/Community.pack/templates/blog/about_this_page.mtml
	'This page contains a single entry by <a href="[_1]">[_2]</a> published on <em>[_3]</em>.' => 'Deze pagina bevat één bericht door <a href="[_1]">[_2]</a> gepubliceerd op <em>[_3]</em>.',

## addons/Community.pack/templates/blog/archive_index.mtml

## addons/Community.pack/templates/blog/archive_widgets_group.mtml

## addons/Community.pack/templates/blog/categories.mtml

## addons/Community.pack/templates/blog/category_archive_list.mtml

## addons/Community.pack/templates/blog/comment_detail.mtml

## addons/Community.pack/templates/blog/comment_form.mtml

## addons/Community.pack/templates/blog/comment_listing.mtml

## addons/Community.pack/templates/blog/comment_preview.mtml
	'Comment on [_1]' => 'Reactie op [_1]',

## addons/Community.pack/templates/blog/comment_response.mtml

## addons/Community.pack/templates/blog/comments.mtml
	'The data in #comments-content will be replaced by some calls to paginate script' => 'De gegevans in #comments-content zullen worden vervangen door een aantal calls naar het paginerings-script',

## addons/Community.pack/templates/blog/content_nav.mtml
	'Blog Home' => 'Hoofdpagina blog',

## addons/Community.pack/templates/blog/current_category_monthly_archive_list.mtml

## addons/Community.pack/templates/blog/dynamic_error.mtml

## addons/Community.pack/templates/blog/entry_create.mtml

## addons/Community.pack/templates/blog/entry_detail.mtml

## addons/Community.pack/templates/blog/entry_form.mtml
	'In order to create an entry on this blog you must first register.' => 'Om een bericht te kunnen aanmaken op deze weblog moet u zich eerst registreren.',
	q{You don't have permission to post.} => q{U heeft geen permissie om een bericht te publiceren.},
	'Sign in to create an entry.' => 'Meld u aan om een bericht te kunnen schrijven.',
	'Select Category...' => 'Selecteer categorie...',

## addons/Community.pack/templates/blog/entry_listing.mtml
	'Recently by <em>[_1]</em>' => 'Recent door <em>[_1]</em>',

## addons/Community.pack/templates/blog/entry_metadata.mtml
	'Vote' => 'Stem',
	'Votes' => 'Stemmen',

## addons/Community.pack/templates/blog/entry.mtml

## addons/Community.pack/templates/blog/entry_response.mtml
	'Thank you for posting an entry.' => 'Bedankt om uw bericht in te sturen.',
	'Entry Pending' => 'Goed te keuren bericht',
	'Your entry has been received and held for approval by the blog owner.' => 'Uw bericht is ontvagen en wordt bewaard tot de blog-eigenaar het goedkeurt.',
	'Entry Posted' => 'Bericht gepubliceerd',
	'Your entry has been posted.' => 'Uw bericht is gepubliceerd.',
	'Your entry has been received.' => 'Uw bericht is ontvangen.',
	q{Return to the <a href="[_1]">blog's main index</a>.} => q{Terugkeren naar de <a href="[_1]">hoofdpagina van de blog</a>.},

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
	'<a href="[_1]">[_2] commented on [_3]</a>: [_4]' => '<a href="[_1]">[_2] reageerde op [_3]</a>: [_4]',

## addons/Community.pack/templates/blog/recent_entries.mtml

## addons/Community.pack/templates/blog/search.mtml

## addons/Community.pack/templates/blog/search_results.mtml

## addons/Community.pack/templates/blog/sidebar.mtml

## addons/Community.pack/templates/blog/syndication.mtml

## addons/Community.pack/templates/blog/tag_cloud.mtml

## addons/Community.pack/templates/blog/tags.mtml

## addons/Community.pack/templates/blog/trackbacks.mtml

## addons/Community.pack/templates/forum/archive_index.mtml

## addons/Community.pack/templates/forum/category_groups.mtml
	'Forum Groups' => 'Forum groepen',
	'Last Topic: [_1] by [_2] on [_3]' => 'Laatste onderwerp: [_1] door [_2] op [_3]',
	'Be the first to <a href="[_1]">post a topic in this forum</a>' => 'Wees de eerste om <a href="[_1]">een onderwerp te starten in dit forum</a>',

## addons/Community.pack/templates/forum/comment_detail.mtml
	'[_1] replied to <a href="[_2]">[_3]</a>' => '[_1] gaf antwoord op <a href="[_2]">[_3]</a>',

## addons/Community.pack/templates/forum/comment_form.mtml
	'Add a Reply' => 'Antwoord toevoegen',

## addons/Community.pack/templates/forum/comment_listing.mtml

## addons/Community.pack/templates/forum/comment_preview.mtml
	'Reply to [_1]' => 'Antwoorden op [_1]',
	'Previewing your Reply' => 'Voorbeeld van antwoord aan het bekijken',

## addons/Community.pack/templates/forum/comment_response.mtml
	'Reply Submitted' => 'Antwoord ingediend',
	'Your reply has been accepted.' => 'Uw antwoord werd aanvaard.',
	'Thank you for replying.' => 'Bedankt om te antwoorden.',
	'Your reply has been received and held for approval by the forum administrator.' => 'Uw antwoord werd ontvangen en wacht op goedkeuring van de forumadministrator.',
	'Reply Submission Error' => 'Fout bij indienen antwoord',
	'Your reply submission failed for the following reasons: [_1]' => 'Het indienen van uw antwoord mislukte wegens: [_1]',
	'Return to the <a href="[_1]">original topic</a>.' => 'Terugkeren naar <a href="[_1]">het oorspronkelijke onderwerp</a>.',

## addons/Community.pack/templates/forum/comments.mtml
	'1 Reply' => '1 Antwoord',
	'# Replies' => '# Antwoorden',
	'No Replies' => 'Geen antwoorden',

## addons/Community.pack/templates/forum/content_header.mtml
	'Start Topic' => 'Onderwerp beginnen',

## addons/Community.pack/templates/forum/content_nav.mtml

## addons/Community.pack/templates/forum/dynamic_error.mtml

## addons/Community.pack/templates/forum/entry_create.mtml
	'Start a Topic' => 'Begin een onderwerp',

## addons/Community.pack/templates/forum/entry_detail.mtml

## addons/Community.pack/templates/forum/entry_form.mtml
	'Topic' => 'Onderwerp',
	'Select Forum...' => 'Selecteer forum...',
	'Forum' => 'Forum',

## addons/Community.pack/templates/forum/entry_listing.mtml

## addons/Community.pack/templates/forum/entry_metadata.mtml

## addons/Community.pack/templates/forum/entry.mtml

## addons/Community.pack/templates/forum/entry_popular.mtml
	'Popular topics' => 'Populaire onderwerpen',
	'Last Reply' => 'Laatste antwoord',
	'Permalink to this Reply' => 'Permanente link naar dit antwoord',
	'By [_1]' => 'Door [_1]',

## addons/Community.pack/templates/forum/entry_response.mtml
	'Thank you for posting a new topic to the forums.' => 'Bedankt om een nieuw onderwerp te publiceren in de forums.',
	'Topic Pending' => 'Onderwerp wacht op goedkeuring',
	'The topic you posted has been received and held for approval by the forum administrators.' => 'Het onderwerp dat u instuurde werd ontvangen en wordt bewaard tot de administratoren van het forum goedkeuren.',
	'Topic Posted' => 'Onderwerp gepubliceerd',
	'The topic you posted has been received and published. Thank you for your submission.' => 'Het onderwerp dat u instuurde werd ontvangen en gepubliceerd.  Bedankt voor uw bijdrage.',
	q{Return to the <a href="[_1]">forum's homepage</a>.} => q{Terugkeren naar de <a href="[_1]">hoofdpagina van het forum</a>.},

## addons/Community.pack/templates/forum/entry_summary.mtml

## addons/Community.pack/templates/forum/entry_table.mtml
	'Recent Topics' => 'Recente onderwerpen',
	'Replies' => 'Antwoorden',
	'Closed' => 'Gesloten',
	'Post the first topic in this forum.' => 'Plaats het eerste onderwerp in dit forum',

## addons/Community.pack/templates/forum/javascript.mtml
	'Thanks for signing in,' => 'Bedankt om u aan te melden,',
	'. Now you can reply to this topic.' => '. Nu kunt u antwoorden op dit onderwerp.',
	'You do not have permission to comment on this blog.' => 'U heeft geen toestemming om reacties achter te laten op deze weblog',
	' to reply to this topic.' => ' om te antwoorden op dit onderwerp.',
	' to reply to this topic,' => ' om te antwoorden op dit onderwerp,',
	'or ' => 'of ',
	'reply anonymously.' => ' reageer anoniem.',

## addons/Community.pack/templates/forum/main_index.mtml
	'Forum Home' => 'Forum hoofdpagina',

## addons/Community.pack/templates/forum/openid.mtml

## addons/Community.pack/templates/forum/page.mtml

## addons/Community.pack/templates/forum/search_results.mtml
	'Topics matching &ldquo;[_1]&rdquo;' => 'Onderwerpen die overeen komen met &ldquo;[_1]&rdquo;',
	'Topics tagged &ldquo;[_1]&rdquo;' => 'Onderwerpen getagd als &ldquo;[_1]&rdquo;',
	'Topics' => 'Onderwerpen',

## addons/Community.pack/templates/forum/sidebar.mtml

## addons/Community.pack/templates/forum/syndication.mtml
	'All Forums' => 'Alle forums',
	'[_1] Forum' => 'Forum [_1]',

## addons/Community.pack/templates/global/email_verification_email.mtml
	'Thank you registering for an account to [_1].' => 'Bedankt om een account te registreren op [_1]',
	'For your own security and to prevent fraud, we ask that you please confirm your account and email address before continuing. Once confirmed you will immediately be allowed to sign in to [_1].' => 'Voor uw eigen veiligheid en om fraude te voorkomen, vragen we om uw account en e-mail adres te bevestigen vooraleer verder te gaan.  Zodra u bevestigd heeft, kunt u onmiddellijk aanmelden bij [_1].',
	q{If you did not make this request, or you don't want to register for an account to [_1], then no further action is required.} => q{Als u hier niet zelf om gevraagd heeft, of u wenst geen account te registreren op [_1], dan is er niets dat u verder hoeft te doen.},

## addons/Community.pack/templates/global/footer.mtml

## addons/Community.pack/templates/global/header.mtml
	'Blog Description' => 'Blogbeschrijving',

## addons/Community.pack/templates/global/javascript.mtml

## addons/Community.pack/templates/global/login_form_module.mtml
	'Logged in as <a href="[_1]">[_2]</a>' => 'Aangemeld als <a href="[_1]">[_2]</a>',
	'Logout' => 'Afmelden',
	'Hello [_1]' => 'Hallo [_1]',
	'Forgot Password' => 'Wachtwoord vergeten',
	'Sign up' => 'Registreer',

## addons/Community.pack/templates/global/login_form.mtml
	'Not a member?&nbsp;&nbsp;<a href="[_1]">Sign Up</a>!' => 'Nog geen lid?&nbsp;&nbsp;<a href="[_1]">Registreer</a>!',

## addons/Community.pack/templates/global/navigation.mtml

## addons/Community.pack/templates/global/new_entry_email.mtml
	q{A new entry '[_1]([_2])' has been posted on your blog [_3].} => q{Een nieuw bericht  '[_1]([_2])' werd gepubliceerd op uw blog [_3].},
	'Author name: [_1]' => 'Auteursnaam: [_1]',
	'Author nickname: [_1]' => 'Bijnaam auteur: [_1]',
	'Title: [_1]' => 'Titel: [_1]',
	'Edit entry:' => 'Bewerk bericht:',

## addons/Community.pack/templates/global/new_password.mtml

## addons/Community.pack/templates/global/new_password_reset_form.mtml
	'Go Back (x)' => 'Ga terug (x)',

## addons/Community.pack/templates/global/profile_edit_form.mtml
	'Go <a href="[_1]">back to the previous page</a> or <a href="[_2]">view your profile</a>.' => 'Ga <a href="[_1]">terug naar de vorige pagina</a> of <a href="[_2]">bekijk uw profiel</a>.',

## addons/Community.pack/templates/global/profile_error.mtml
	'ERROR MSG HERE' => 'FOUTBOODSCHAP HIER',
	'Go Back' => 'Ga terug',

## addons/Community.pack/templates/global/profile_feed.mtml
	'Posted [_1] to [_2]' => 'Publiceerde [_1] op [_2]',
	'Commented on [_1] in [_2]' => 'Reageerde op [_1] op [_2]',
	'Voted on [_1] in [_2]' => 'Stemde op [_1] op [_2]',
	'[_1] voted on <a href="[_2]">[_3]</a> in [_4]' => '[_1] stemde op <a href="[_2]">[_3]</a> op [_4]',

## addons/Community.pack/templates/global/profile_view.mtml
	'User Profile' => 'Gebruikersprofiel',
	'Recent Actions from [_1]' => 'Recente acties van [_1]',
	'You are following [_1].' => 'U volgt [_1].',
	'Unfollow' => 'Niet langer volgen',
	'Follow' => 'Volgen',
	'You are followed by [_1].' => 'U wordt gevolgd door [_1].',
	'You are not followed by [_1].' => 'U wordt niet gevolgd door [_1].',
	'Website:' => 'Website:',
	'Recent Actions' => 'Recente acties',
	'Comment Threads' => 'Reactie threads',
	'Commented on [_1]' => 'Reageerde op [_1]',
	'Favorited [_1] on [_2]' => 'Maakte [_1] favoriet op [_2]',
	'No recent actions.' => 'Geen recente acties.',
	'[_1] commented on ' => '[_1] reageerde op ',
	'No responses to comments.' => 'Geen antwoorden op reacties.',
	'Not following anyone' => 'Volgt niemand',
	'Not being followed' => 'Wordt niet gevolgd',

## addons/Community.pack/templates/global/register_confirmation.mtml
	'Authentication Email Sent' => 'Authenticatiemail verzonden',
	'Profile Created' => 'Profiel aangemaakt',

## addons/Community.pack/templates/global/register_form.mtml

## addons/Community.pack/templates/global/register_notification_email.mtml

## addons/Community.pack/templates/global/search.mtml

## addons/Community.pack/templates/global/signin.mtml
	'You are signed in as <a href="[_1]">[_2]</a>' => 'U bent aangemeld als <a href="[_1]">[_2]</a>',
	'You are signed in as [_1]' => 'U bent aangemeld als [_1]',
	'Edit profile' => 'Profiel bewerken',
	'Not a member? <a href="[_1]">Register</a>' => 'Nog geen lid? <a href="[_1]">Registreer nu</a>',

## addons/Community.pack/tmpl/cfg_community_prefs.tmpl
	'Community Settings' => 'Community instellingen',
	'Anonymous Recommendation' => 'Anonieme aanbevelingen',
	'Check to allow anonymous users (users not logged in) to recommend discussion.  IP address is recorded and used to identify each user.' => 'Kruis dit vakje aan om anonieme gebruikers (gebruikers die niet zijn aangemeld) toe te laten discussies aan te raden.  Het IP adres van de gebruiker wordt gebruikt om gebruikers uit elkaar te houden.',
	'Allow anonymous user to recommend' => 'Anonieme gebruikers toelaten aanbevelingen te doen',
	'Junk Filter' => 'Junk Filter',
	'If enabled, all moderated entries will be filtered by Junk Filter.' => 'Indien ingeschakeld zullen alle gemodereerde berichten gefilterd worden door Junk Filter',
	'Save changes to blog (s)' => 'Wijzigingen aan blog opslaan (s)',

## addons/Community.pack/tmpl/widget/blog_stats_registration.mtml
	'Recent Registrations' => 'Recent geregistreerd',
	'default userpic' => 'standaardfoto gebruiker',
	'You have [quant,_1,registration,registrations] from [_2]' => 'U heeft [quant,_1,registratie,registraties] op [_2]',

## addons/Community.pack/tmpl/widget/most_popular_entries.mtml
	'There are no popular entries.' => 'Er zijn geen populaire berichten.',

## addons/Community.pack/tmpl/widget/recently_scored.mtml
	'There are no recently favorited entries.' => 'Er zijn geen recente favoriete berichten.',

## addons/Community.pack/tmpl/widget/recent_submissions.mtml
);

1;
