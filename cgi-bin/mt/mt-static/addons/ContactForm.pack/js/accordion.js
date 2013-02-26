jQuery(function($) {
	var $h3 = $('#group-settings h3'),
		$toggleBtn = $('span', $h3),
		$fields = $('div.group-setting-content'),
		speed = 500,
		plus = 'togglePlus',
		minus = 'toggleMinus';
	$h3.click(function() {
		var $self = $(this),
			$btn = $self.children();
			index = $h3.index(this);
		if($btn.hasClass(plus)) {
			$btn.addClass(minus)
			    .removeClass(plus);
			$fields.filter(':eq(' + index + ')').stop(true, true).slideDown(speed);
			$self.css('margin-bottom', 0);
		} else if($btn.hasClass(minus)) {
			$btn.addClass(plus)
			    .removeClass(minus);
			$fields.filter(':eq(' + index + ')').stop(true, true).slideUp(speed, function() {
				$self.css('margin-bottom', 10);
			});
		}
	});
	$.fx.off = true;
	$h3.trigger('click');
	$.fx.off = false;
});
