$(function() {
  function toggle_height(div, ele) {
    if (ele) div = $(ele);
    if ($('body').hasClass('upstream') && div.parent().hasClass('past')) return;
    div.css({ 'height': (div.hasClass('verbose') ? 0 : div.children().outerHeight() + 30) }).toggleClass('verbose');
    div.siblings('.names').toggleClass('verbose', div.hasClass('verbose'));
  };
  $('.changes p, .changes > div').on('click', function(event) {
    event.stopPropagation();
    toggle_height($(event.target).parents('.changes'));
  });
  $('ul.children, span.names').on('click', function(event) {
    event.stopPropagation();
    toggle_height($(event.target).siblings('.changes'));
  });
  $('li.commit').on('click', function(event) {
    event.stopPropagation();
    toggle_height($(event.target).children('.changes'));
  });
  $('.show-all').on('click', function(event) {
    $('body').addClass('verbose');
    $('.changes').removeClass('verbose').each(toggle_height);
  });
  $('.hide-all').on('click', function(event) {
    $('body').removeClass('verbose');
    $('.changes').addClass('verbose').each(toggle_height);
  });
  $('li a').on('click', function(event) { event.stopPropagation(); });
  $('.changes > div').each(function(index, div) {
    $(div).height($(div).outerHeight());
  });
  $('.show-past').on('click', function(event) { $('body').removeClass('upstream'); });
  $('.hide-past').on('click', function(event) { $('body').addClass('upstream'); });

  (function(user) {
    var branch = $('a:contains(' + user + '/master)').parent().parent().addClass('head');
    branch.addClass('relevant').find('li.commit').addClass('relevant');
    branch.parents('li.commit').addClass('relevant past');
    branch.parents('ul.children').addClass('relevant past');
    $('li.commit:not(.relevant)').addClass('irrelevant'); // css({display: 'none'});
  })($('h2 a').text().replace(/\s+|\/.+$/mg, ''))
  setTimeout(function() {
    $('body').addClass('upstream');
    var count = $('.names a').length;
    if (count > 0) $('h2').text($('h2').text().replace(/\s+$/, '')).append("<sup>(" + $('li.commit').length + " unique / " + count + " branches)</sup>");
  }, 1000);
  $('h1').wrap('<a href="../../"></a>');
});
