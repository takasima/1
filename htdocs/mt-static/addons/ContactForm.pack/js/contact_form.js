(function($) {
    var o = {
        options: null,
        
        typeConfig: {
            text: {
                visibility: {
                    opt: false,
                    size: false,
                    def: true,
                    validate: false,
                    length: true
                },
                defaultType: 'text'
            },
            textarea: {
                visibility: {
                    opt: false,
                    size: false,
                    def: true,
                    validate: false,
                    length: true
                },
                defaultType: 'textarea'
            },
            checkbox: {
                visibility: {
                    opt: true,
                    size: false,
                    def: true,
                    validate: true,
                    length: false
                },
                defaultType: 'checkbox'
            },
            select: {
                visibility: {
                    opt: true,
                    size: false,
                    def: true,
                    validate: true,
                    length: false
                },
                defaultType: 'select'
            },
            radio: {
                visibility: {
                    opt: true,
                    size: false,
                    def: true,
                    validate: true,
                    length: false
                },
                defaultType: 'radio'
            },
            checkbox_multiple: {
                visibility: {
                    opt: true,
                    size: false,
                    def: true,
                    validate: true,
                    length: false
                },
                defaultType: 'checkbox_multiple'
            },
            select_multiple: {
                visibility: {
                    opt: true,
                    size: true,
                    def: true,
                    validate: true,
                    length: false
                },
                defaultType: 'select_multiple'
            },
            url: {
                visibility: {
                    opt: false,
                    size: false,
                    def: true,
                    validate: true,
                    length: true
                },
                defaultType: 'text'
            },
            email: {
                visibility: {
                    opt: false,
                    size: false,
                    def: true,
                    validate: true,
                    length: true
                },
                defaultType: 'text'
            },
            date: {
                visibility: {
                    opt: false,
                    size: false,
                    def: false,
                    validate: true,
                    length: true
                },
                defaultType: 'hidden'
            },
            date_and_time: {
                visibility: {
                    opt: false,
                    size: false,
                    def: false,
                    validate: true,
                    length: true
                },
                defaultType: 'hidden'
            },
            tel: {
                visibility: {
                    opt: false,
                    size: false,
                    def: true,
                    validate: true,
                    length: true
                },
                defaultType: 'text'
            },
            zip_code: {
                visibility: {
                    opt: false,
                    size: false,
                    def: true,
                    validate: true,
                    length: true
                },
                defaultType: 'text'
            },
            other: {
                visibility: {
                    opt: true,
                    size: true,
                    def: true,
                    validate: true,
                    length: true
                },
                defaultType: 'text'
            }
        },
        
        $fields: null,
        
        $formElements: null,
        
        _create: function() {
            this._setupElements();
            this._eventify();
        },
        
        _init: function() {
            var type = $('option:selected', this.$formElements.type).val().replace(/-/g, '_');
            this._applyVisibility(type);
            this._changeDefaultType(type);
        },
        
        _setupElements: function() {
            this.$fields = {
                opt: $('#options-field'),
                size: $('#size-field'),
                def: $('#default-field'),
                validate: $('#validate-field'),
                length: $('#check_length-field')
            };
            this.$formElements = {
                type: $('#type'),
                opt: $('#options')
            };
        },
        
        _eventify: function() {
            var self = this,
                $type = this.$formElements.type,
                $options = this.$formElements.opt,
                tmpOptions = null;
            $type.change(function() {
                var $self = $(this),
                    mode = $self.val().replace(/-/g, '_');
                self._applyVisibility(mode);
                self._changeDefaultType(mode);
            });
            $options
                .focus(function() {
                    tmpOptions = $(this).val();
                })
                .blur(function() {
                    if(tmpOptions != $(this).val()) {
                        $type.trigger('change');
                    }
                });
        },
        
        _applyVisibility: function(mode) {
            var obj,
                name = '',
                config = this.typeConfig;
            if(!config[mode]) {
                mode = 'other';
            }
            obj = config[mode].visibility;
            for(name in obj) {
                if(obj.hasOwnProperty(name)) {
                    this.$fields[name].toggleClass('hidden', !obj[name]);
                }
            }
        },
        
        _changeDefaultType: function(mode) {
            var config = this.typeConfig,
                defType,
                html;
            if(!config[mode]) {
                mode = 'other';
            }
            defType = config[mode].defaultType || 'text';
            html = this._createDefaultTag(defType);
            if(html) {
                $('.field-content', this.$fields.def).html(html);
            }
            if(mode === 'checkbox') {
                $('#default_cb_btn').change(function() {
                    var $self = $(this),
                        $default = $('#default'),
                        size = $self.filter(':checked').size();
                    if(size) {
                        $default.val('1');
                    } else {
                        $default.val('0');
                    }
                });
            } else if(mode === 'checkbox_multiple') {
                $('input[name="default_cbs"]').change(function() {
                    var $default = $('#default'),
                        val;
                    val = $('input[name="default_cbs"]:checked').map(function() {
                        return $(this).val();
                    }).get().join(',');
                    $default.val(val);
                });
            } else if(mode === 'select_multiple') {
                $('#default_select').change(function() {
                    var $self = $(this),
                        $default = $('#default'),
                        val;
                    val = $self.find('option:selected').map(function() {
                        return $(this).val();
                    }).get().join(',');
                    $default.val(val);
                });
            }
        },
        
        _getOptionAsArray: function() {
            var s = this.$formElements.opt.val();
            s = s.replace(/&/g,'&amp;');
            s = s.replace(/>/g,'&gt;');
            s = s.replace(/</g,'&lt;');
            var result = s.split(',');
            return result;
        },
        
        _createDefaultTag: function(defType) {
            var tag = '',
                defaultValue = this.options.defaultValue;
            switch(defType) {
                case 'text':
                    return '<input type="text" name="default" id="default" value="' + defaultValue + '" class="text full-width ti">';
                case 'textarea':
                    return '<textarea name="default" id="default" class="text full-width ta" rows="3" cols="72">' + defaultValue + '</textarea>';
                case 'checkbox':
                    var checked = '';
                    if(defaultValue == '1') {
                        checked = ' checked="checked"';
                    }
                    var label = $('#options').val();
                    label = label.replace(/&/g,'&amp;');
                    label = label.replace(/>/g,'&gt;');
                    label = label.replace(/</g,'&lt;');
                    return '<p class="hint first-child last-child"><input type="hidden" id="default" name="default" value="' + defaultValue + '"><input type="checkbox" name="default_cb_btn" value="' + defaultValue + '" id="default_cb_btn" class="cb"' + checked + '> <label class="hint" for="default">' + label + '</label></p>';
                case 'select':
                    var opt = this._getOptionAsArray();
                    tag += '<select name="default" id="default" class="se" mt:watch-change="1">';
                    for(var i = 0, max = opt.length, val, selected; i < max; i++) {
                        val = opt[i];
                        selected = '';
                        if(val == defaultValue) {
                            selected = ' selected="selected"';
                        }
                        tag += '<option value="' + val + '"' + selected + '>' + val + '</option>';
                    }
                    tag += '</select>';
                    return tag;
                case 'radio':
                    var opt = this._getOptionAsArray();
                    tag += '<ul class="custom-field-radio-list">';
                    for(var i = 0, max = opt.length, val, index, checked; i < max; i++) {
                        val = opt[i];
                        index = i + 1;
                        checked = '';
                        if(val == defaultValue) {
                            checked = ' checked="checked"';
                        }
                        tag += '<li><input type="radio" name="default" value="' + val + '" id="default_' + index + '" class="rb"' + checked + '> <label for="default_' + index + '">' + val + '</label></li>';
                    }
                    tag += '</ul>';
                    return tag;
                case 'checkbox_multiple':
                    var opt = this._getOptionAsArray();
                    tag += '<ul class="custom-field-radio-list">';
                    tag += '<input type="hidden" id="default" name="default" value="' + defaultValue + '">';
                    for(var i = 0, max = opt.length, val, index, defaultValueArray, checked, j; i < max; i++) {
                        val = opt[i];
                        index = i + 1;
                        defaultValueArray = defaultValue.split(',');
                        checked = '';
                        j = defaultValueArray.length;
                        while(j--) {
                            if(val == defaultValueArray[j]) {
                                checked = ' checked="checked"';
                                break;
                            }
                        }
                        tag += '<li><input type="checkbox" name="default_cbs" value="' + val + '" id="default_' + index + '" class="cb"' + checked + '> <label for="default_' + index + '">' + val + '</label></li>';
                    }
                    tag += '</ul>';
                    return tag;
                case 'select_multiple':
                    var opt = this._getOptionAsArray(),
                        sizeTag = '',
                        selectSize = this.options.selectSize;
                    if(0 < selectSize) {
                        sizeTag = ' size="' + selectSize + '"';
                    }
                    tag += '<input type="hidden" id="default" name="default" value=""><select multiple="multiple" name="default_select" id="default_select" class="se"' + sizeTag + ' mt:watch-change="1">';
                    for(var i = 0, max = opt.length, val, defaultValueArray, selected, j; i < max; i++) {
                        val = opt[i];
                        defaultValueArray = defaultValue.split(',');
                        selected = '';
                        j = defaultValueArray.length;
                        while(j--) {
                            if(val == defaultValueArray[j]) {
                                selected = ' selected="selected"';
                                break;
                            }
                        }
                        tag += '<option value="' + val + '"' + selected + '>' + val + '</option>';
                    }
                    tag += '</select>';
                    return tag;
                case 'hidden':
                    return '<input type="hidden" id="default" name="default" value="' + defaultValue + '">';
                default:
                    return false;
            }
        },
        
        addType: function(obj) {
            var type, name;
            for(name in obj) {
                if(obj.hasOwnProperty(name)) {
                    if(!this.typeConfig[name]) {
                        this.typeConfig[name] = obj[name];
                    }
                }
            }
        }
    };
    
    $.fn.contactForm = function(options) {
        var opts = $.extend({}, {
            defaultValue: '',
            selectSize: 0
        }, options);
        
        return this.each(function() {
            o.options = opts;
            o._create();
            o._init();
        });
    };
    
    $.contactForm = {};
    
    $.contactForm.addType = function(obj) { o.addType(obj) };
})(jQuery);
