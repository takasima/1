/* フィールドの入力チェック */

/* validator.js が必要  */

(function($) {

    var fieldValidator = new Validator();

    /* カテゴリ入力チェック */
    fieldValidator.append(function (form, params) {
        if (!params.category_equired) return true;

        var caregory_id = parseInt(form.find("input[name='category_ids']").val().split(/,/)[0]);
        if (isFinite(caregory_id) && caregory_id > 0) {
            return true;
        }
        this.errors.push('カテゴリは必須項目です。');
        return false;
    });

    /* フィールド入力チェック */
    fieldValidator.append(function (form, params) {
        var self = this;
        $.each(params.standard_fields, function (label, name) {
            var input = form.find(":input[name='"+name+"']");
            if (input.length == 0) return;
            var val;
            switch (input.attr('type')) {
                case 'checkbox':
                    val = input.filter(':checked').val();
                    break;
                case 'radio':
                    val = input.filter(':checked').val();
                    break;
                default:
                    val = input.val();
                    break;
            }
            if (!(val && val.match(/\S/))) {
                self.errors.push(label + 'は必須項目です。');
            }
        });
        return true;
    });

    /* カスタムフィールド入力チェック */
    fieldValidator.append(function (form, params) {
        var self = this;

        form.find('.field').filter('.required').each(function() {
            var field = $(this);
            var name = field.attr('id').replace(/-field/, '');
            var label = form.find('label#'+name + '-label').text().replace(/\s+\*$/, '');
            var input = form.find('input[name="'+name+'"]');
            if (input.length > 0) { // radioだと1つ以上
                var val;
                switch (input.attr('type')) {
                    case 'checkbox':
                        val = input.filter(':checked').val();
                        break;
                    case 'radio':
                        val = input.filter(':checked').val();
                        break;
                    default:
                        val = input.val();
                        break;
                }
                if (!(val && val.match(/\S/))) {
                    self.errors.push(label + 'は必須項目です。');
                }
                return;
            }

            var textarea = form.find('textarea[name="'+name+'"]');
            if (textarea.length == 1) {
                if (! textarea.val().match(/\S/)) {
                    self.errors.push(label + 'は必須項目です。');
                }
                return;
            }

            var select = form.find('select[name="'+name+'"]');
            if (select.length == 1) {
                if (! select.val().match(/\S/)) {
                    self.errors.push(label + 'は必須項目です。');
                }
                return;
            }

            // 日付と時刻, 日付, 時刻 どれでもフィールド自体は両方ある
            // 日付がtype="hidden" => 時刻
            // 時刻がtype="hidden" => 日付
            // どちらでもない => 日付と時刻
            var date = form.find('input[name="d_'+name+'"]');
            var time = form.find('input[name="t_'+name+'"]');
            if (date.length == 1 && time.length == 1) {
                var val;
                var time_val = time.val();
                var date_val = date.val();
                if (date.attr('type') == 'hidden') {
                    val = time_val;
                } else if (time.attr('type') == 'hidden') {
                    val = date_val;
                } else {
                    val = date_val && time_val ? date_val+' '+time_val : '';
                }

                if (!(val && val.match(/\S/))) {
                    self.errors.push(label + 'は必須項目です。');
                }
                return;
            }
        });
        return true;
    });

    /* 拡張フィールド入力チェック */
    /* 拡張フィールドのラベル名がhiddenフィールドで渡されることを利用してname値を得る
       また、nameにフィールドの型名が含まれることから型別に適切な処理に振り分ける */
    fieldValidator.append(function (form, params) {
        var self = this;
        $.each(params.ext_fields, function () {
            var label = this;
            var input = form.find('input:hidden[value="'+label+'"]');
            if (input.length == 0) return;
            var label_name = input.attr('name') || '';
            var matches = label_name.match(/^(.+-([^\-]+))-label$/);
            if (matches == null) return;
            var name = matches[1];
            var type = matches[2];
            var fields = form.find(':input[name="'+name+'"]');
            if (fields.length == 0) {
                //
            } else {
                /* typeにあわせて適切な未入力判定を行う */
                switch (type) {
                    case 'text':
                    case 'textarea':
                    case 'select':
                        if (!(fields.val().match(/\S/))) {
                            self.errors.push(label + 'は必須項目です。');
                        }
                        break;
                    case 'file':
                    case 'file_compact':
                        var fullpath_field =  form.find(':input[name="'+name+'-fullpath"]');
                        var fullpath = fullpath_field.length > 0 ? fullpath_field.val() : '';
                        if (!(fields.val().match(/\S/) || fullpath.match(/\S/))) {
                            self.errors.push(label + 'は必須項目です。');
                        }
                        break;
                    case 'radio':
                    case 'checkbox':
                        val = fields.filter(':checked').val();
                        if (!(val && val.match(/\S/))) {
                            self.errors.push(label + 'は必須項目です。');
                        }
                        break;
                    case 'cbgroup':
                        // 拡張チェックボックスグループがあるので関連フィールドを調べる
                        if (fields.val() == 1) {
                            var cbgroup_checked = false;
                            var max_no = form.find(':input[name="'+name+'-multiple"]').val().split(',').length;
                            for (no=1; no<=max_no; no++) {
                                if (form.find(':input[name="'+name+no+'"]').filter(':checked').val()) {
                                    cbgroup_checked = true;
                                    break;
                                }
                            }
                            if (cbgroup_checked == false) {
                                self.errors.push(label + 'は必須項目です。');
                            }
                        }
                        break;
                    case 'date':
                        var date = fields;
                        var time = form.find('input[name="'+name+'-time"]');
                        var time_val = time.val();
                        var date_val = date.val();
                        var val = date_val && time_val ? date_val+' '+time_val : '';
                        if (!(val && val.match(/\S/))) {
                            self.errors.push(label + 'は必須項目です。');
                        }
                        break;
                }
            }
        });
        return true;
    });

    /* フィールド書式チェック */
    fieldValidator.append(function (form, params) {
        var self = this;

        var datefield_matcher = /^(?:.+_on_date|extfields-.+-date|d_customfield_.+)$/;
        var timefield_matcher = /^(?:.+_on_time|extfields-.+-date-time|t_customfield_.+)$/;

        var date_format = /^\d{4}-\d{2}-\d{2}$/;
        var time_format = /^\d{2}:\d{2}:\d{2}$/;

        form.find('input[type="text"]').each(function() {
            var field = $(this);
            var val = field.val();
            var name = field.attr('name') || '';
            if (!(val && val.match(/\S/))) return;

            var label = field.closest('.field').find('label').text().replace(/^\s+/, '').replace(/\s+\*$/, '') || name;

            // カスタムフィールド「日付と時刻」及び_on_date/on_timeは一方のみの入力は不可（エラーになる）
            var m;
            if (m = name.match(/^d_customfield_(.+)$/)) {
                var name_t = 't_customfield_' + m[1];
                var field_t = form.find('input[type="text"][name="'+name_t+'"]');
                if (field_t.length > 0 && !(field_t.val().match(/\S/)))
                    self.errors.push(label + 'の時刻を HH:MM:SS 形式で記入して下さい。');
            } else if (m = name.match(/^t_customfield_(.+)$/)) {
                var name_d = 'd_customfield_' + m[1];
                var field_d = form.find('input[type="text"][name="'+name_d+'"]');
                if (field_d.length > 0 && !(field_d.val().match(/\S/)))
                    self.errors.push(label + 'の日付を YYYY-MM-DD 形式で記入して下さい。');
            }
            if (m = name.match(/^(.+)_on_date$/)) {
                var name_t = m[1] + '_on_time';
                var field_t = form.find('input[type="text"][name="'+name_t+'"]');
                if (field_t.length > 0 && !(field_t.val().match(/\S/)))
                    self.errors.push(label + 'の時刻を HH:MM:SS 形式で記入して下さい。');
            } else if (m = name.match(/(.+)_on_time$/)) {
                var name_d = m[1] + '_on_date';
                var field_d = form.find('input[type="text"][name="'+name_d+'"]');
                if (field_d.length > 0 && !(field_d.val().match(/\S/)))
                    self.errors.push(label + 'の日付を YYYY-MM-DD 形式で記入して下さい。');
            }

            if (datefield_matcher.test(name) && !date_format.test(val))
                self.errors.push(label + 'の日付は YYYY-MM-DD 形式で記入して下さい。');
            if (timefield_matcher.test(name) && !time_format.test(val))
                self.errors.push(label + 'の時刻は HH:MM:SS 形式で記入して下さい。');
        });
        return true;
    });

    $.fn.checkFields = function (params) {
        if (fieldValidator.run(this, params)) {
            return true;
        }
        window.alert(fieldValidator.errors.join("\r\n"));
        return false;
    }

})(jQuery);
