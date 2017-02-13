(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

ga('create', 'UA-88354576-1', 'auto');
ga('send', 'pageview');

$(document).on('change', 'select', function(e) {
  ga('send', 'event', 'Dropdown', 'Change', $(e.currentTarget).val());
});

$(document).on('click', 'input', function(e) {
  ga('send', 'event', 'Input', 'Click', $(e.currentTarget).val());
});

$(document).on('click', 'a', function(e) {
  ga('send', 'event', 'Link', 'Click', $(e.currentTarget).attr("href"));
});
