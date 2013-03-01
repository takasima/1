jQuery(function($) {
    $('input.contact-form-text-date').datepicker({
        dateFormat: 'yy-mm-dd',
        showMonthAfterYear: true,
        monthNames: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
        yearSuffix: '年',
        dayNamesMin: ['日', '月', '火', '水', '木', '金', '土']
    });

    $("div.contact-form").each(function() {
        var $contact_form   = $(this),
            _hdlr_highlight = function() {
                $contact_form.find(".contact-form-field").removeClass("highlight")
                    .has(this).addClass("highlight");
            };
        $contact_form
            .find("input, textarea, select")
                .bind({
                    focus: _hdlr_highlight,
                    blur: function() {
                        $(this).parents(".contact-form-field").eq(0).removeClass("highlight");
                    }
                })
            .end()
            .filter('[type="checkbox"], [type="radio"]')
                .bind("click", _hdlr_highlight)
            .end()
            .find(".contact-form-field").has('ul input[type="radio"], ul input[type="checkbox"]')
                .find("p.form-label")
                    .bind("click", _hdlr_highlight);
    });
});
