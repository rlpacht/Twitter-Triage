// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function clickHandler(event) {
  debugger
  var $parentLi = $(this).parent();
  if ($parentLi.children().length > 1 && $parentLi.children()[1].checked === true) {
    var mentionsLength = Number($parentLi.children()[1].dataset.mentions);
  }
  var newHref = chooseTwitterResponse(this.dataset, this.classList[0]);
  $(this).attr("href", newHref);
}

function chooseTwitterResponse(dataset, typeString) {
  var responses;
  switch (typeString) {
    case "pale":
      responses = paleResponses;
      break;
    case "dark":
      responses = darkResponses;
      break;
    case "agnostic":
      responses = agnosticResponses;
      break;
  }

  // Sorted from longest to shortest
  var sortedResponses = _.sortBy(responses, function(response) {
    return -response.length;
  });

  var mentionsLength = dataset.mentions;
  var username = dataset.username;
  var shortResponses = sortedResponses.filter(function(response) {
    console.log(response.length + username.length + 2 + mentionsLength);
    return response.length + username.length + 2 + mentionsLength < 129;
  });

  var reply;
  if (shortResponses.length === 0) {
    reply = encodeURI(_.last(sortedResponses));
  } else {
    reply = encodeURI(shortResponses[0]);
  }

  var tweetId = dataset.id;
  return  "https://twitter.com/intent/tweet?in_reply_to=" + tweetId + "&text=" + reply;
}

$(function() {
  var $pale = $(".pale");
  var $dark = $(".dark");
  var $agnostic = $(".agnostic");
  $(".tweet-reply-controls").on("click", clickHandler);
  // $pale.on("click", clickHandler);
  // $dark.on("click", clickHandler);
  // $agnostic.on("click", clickHandler);
});

var paleResponses = [
  "Try melange.com! Custom foundation mixed just for you to perfectly match your skin color, no matter how light! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin color, no matter how light! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin, no matter how light! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin, no matter how light! Try for free!",
  "Try melange.com! Custom foundation that perfectly matches your skin, no matter how light! Try free!"
];

var darkResponses = [
  "Try melange.com! Custom foundation mixed just for you to perfectly match your skin color, no matter how dark! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin color, no matter how dark! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin, no matter how dark! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin, no matter how dark! Try for free!",
  "Try melange.com! Custom foundation that perfectly matches your skin, no matter how dark! Try free!",
  "Try melange.com! Custom foundation that perfectly matches your skin no matter how dark! Try free"
];

var agnosticResponses = [
  "Try melange.com! Custom foundation mixed just for you to perfectly match your skin color! Snap a selfie & get free samples!",
  "Try melange.com! Custom foundation mixed just for you to perfectly match your skin color! Get free samples!",
  "Try melange.com! Custom foundation mixed just for you to perfectly match your skin color! Try for free!",
  "Try melange.com! Custom foundation mixed just for you to perfectly match your skin color! Try free!",
  "Try melange.com! Custom foundation that perfectly matches your skin color! Get free samples!",
  "Try melange.com! Custom foundation that perfectly matches your skin color! Try it free!",
  "Try melange.com! Custom foundation that perfectly matches your skin color! Try free!"
];
