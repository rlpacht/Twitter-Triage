// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function clickHandler(event) {
  var $tableCell = $(this).parents('td.tweet-reply-controls');
  var $checkbox = $tableCell.find('input.include-mentions-count');
  var mentions;
  if ($checkbox.length > 0 && $checkbox.is(":checked")) {
    mentionsLength = Number(this.dataset.mentions);
  } else {
    mentionsLength = 0;
  }
  var newHref = chooseTwitterResponse(this.dataset, this.classList[0], mentionsLength);
  $(this).attr("href", newHref);
}

function chooseTwitterResponse(dataset, typeString, mentionsLength) {
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

  var username = dataset.user;
  var shortResponses = sortedResponses.filter(function(response) {
    return response.length + username.length + 2 + mentionsLength < 129;
  });

  var reply;
  if (shortResponses.length === 0) {
    reply = ""
  } else {
    reply = encodeURI(shortResponses[0]);
  }

  var tweetId = dataset.id;
  return  "https://twitter.com/intent/tweet?in_reply_to=" + tweetId + "&text=" + reply;
}

$(document).ready(bindReplyHandlers);
$(document).on('page:load', bindReplyHandlers);

function bindReplyHandlers() {
  $(".reply-option").on("click", clickHandler);
}

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
