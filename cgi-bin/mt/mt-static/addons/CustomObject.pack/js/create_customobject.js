(function($) {
    $.Inflector = {};
    
    $.Inflector.rules = {
        pluralRules : {
            '/(s)tatus$/i':'RegExp.$1+"tatuses"',
            '/^(ox)$/i':'RegExp.$1+"en"',
            '/([m|l])ouse$/i':'RegExp.$1+"ice"',
            '/(matr|vert|ind)ix|ex$/i':'RegExp.$1+"ices"',
            '/(x|ch|ss|sh)$/i':'RegExp.$1+"es"',
            '/(r|t|c)y$/i':'RegExp.$1+"ies"',
            '/(hive)$/i':'RegExp.$1+"s"',
            '/(?:([^f])fe|([lr])f)$/i':'RegExp.$1+RegExp.$2+"ves"',
            '/(.*)sis$/i':'RegExp.$1+"ses"',
            '/([ti])um$/i':'RegExp.$1+"a"',
            '/(buffal|tomat)o$/i':'RegExp.$1+"oes"',
            '/(bu)s$/i':'RegExp.$1+"ses"',
            '/(alias)/i':'RegExp.$1+"es"',
            '/(octop|vir)us$/i':'RegExp.$1+"i"',
            '/(.*)s$/i':'RegExp.$1+"s"',
            '/(.*)/i':'RegExp.$1+"s"'
        },
        uninflected : [
            'deer', 'fish', 'measles', 'ois', 'pox', 'rice', 'sheep', 'Amoyese', 'bison', 'bream', 'buffalo', 'cantus', 'carp', 'cod', 'coitus', 'corps', 'diabetes', 'elk', 'equipment', 'flounder', 'gallows', 'Genevese', 'Gilbertese', 'graffiti', 'headquarters', 'herpes', 'information', 'innings', 'Lucchese', 'mackerel', 'mews', 'moose', 'mumps', 'news', 'nexus', 'Niasese', 'Pekingese', 'Portuguese', 'proceedings', 'rabies', 'salmon', 'scissors', 'series', 'shears', 'siemens', 'species', 'testes', 'trousers', 'trout', 'tuna', 'whiting', 'wildebeest', 'Yengeese'
        ],
        pluralIrregular : {
            'atlas':'atlases',
            'child':'children',
            'corpus':'corpuses',
            'ganglion':'ganglions',
            'genus':'genera',
            'graffito':'graffiti',
            'leaf':'leaves',
            'man':'men',
            'money':'monies',
            'mythos':'mythoi',
            'numen':'numina',
            'opus':'opuses',
            'penis':'penises',
            'person':'people',
            'sex':'sexes',
            'soliloquy':'soliloquies',
            'testis':'testes',
            'woman':'women',
            'move':'moves'
        }
    };
    
    $.Inflector.pluralize = function(word) {
        var rules = $.Inflector.rules,
            item;
        for(item in rules.uninflected) {
            if(rules.uninflected.hasOwnProperty(item)) {
                if(word.toLowerCase() === rules.uninflected[item]) {
                    return word;
                }
            }
        }
        for(item in rules.pluralIrregular) {
            if(rules.pluralIrregular.hasOwnProperty(item)) {
                if(word.toLowerCase() === item) {
                    word = rules.pluralIrregular[item];
                    return word;
                }
            }
        }
        for(item in rules.pluralRules) {
            if(rules.pluralRules.hasOwnProperty(item)) {
                try{
                    var rObj = eval("new RegExp(" + item + ");");
                    if(word.match(rObj)) {
                        word = word.replace(rObj, eval(rules.pluralRules[item]));
                        return word;
                    }
                } catch(e) {
                    alert(e.description);
                }
            }
        }
        return word;
    };
})(jQuery);

(function($) {
    $.fn.fillEnglishFields = function(options) {
        var opts = $.extend({}, {
            plural_expr: '#plural',
            description_expr: '#description'
        }, options);
        
        return this.each(function() {
            eventify($(this), opts);
        });
    };
        
    function eventify($obj, opts) {
        var $plural = $(opts.plural_expr),
            $description = $(opts.description_expr),
            exValue;
        $obj
            .focus(function() {
                exValue = $(this).val();
            })
            .blur(function() {
                var $self = $(this),
                    id;
                if(exValue !== $self.val()) {
                    id = $self.val();
                    $plural.val(createPluralValue(id));
                    $description.val(createDescriptionValue(id));
                }
            });
    }
    
    function createPluralValue(text) {
        var val = "";
        if(text) {
            val = $.Inflector.pluralize(text);
        } else {
            val = "";
        }
        return val;
    }
    
    function createDescriptionValue(text) {
        var val = "";
        if(text) {
            val = "Create and Manage " + text + ".";
        } else {
            val = "";
        }
        return val;
    }
})(jQuery);

(function($) {
    $.fn.fillJapaneseFields = function(options) {
        var opts = $.extend({}, {
            description_ja_expr: '#description_ja'
        }, options);
        
        return this.each(function() {
            eventify($(this), opts);
        });
    };
        
    function eventify($obj, opts) {
        var $description_ja = $(opts.description_ja_expr),
            exValue;
        $obj
            .focus(function() {
                exValue = $(this).val();
            })
            .blur(function() {
                var $self = $(this),
                    ja;
                if(exValue !== $self.val()) {
                    ja = $self.val();
                    $description_ja.val(createDescriptionJaValue(ja));
                }
            });
    }
    
    function createDescriptionJaValue(text) {
        var val = "";
        if(text) {
            val = text + "の作成と管理をします。";
        } else {
            val = "";
        }
        return val;
    }
})(jQuery);

jQuery(function() {
    var $id = jQuery('#plugin_id'),
        $ja = jQuery('#ja');
    $id.fillEnglishFields();
    $ja.fillJapaneseFields();
});
