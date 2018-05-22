## Summary

Simple tool to watch your friends list for friends playing a certain game.

## Description

Steam lets you get notifications when your friends play games.  Via your notification settings, you can choose to only see notifications about certain friends.

However, you can't choose to only see notifications about certain games, which is annoying when you have a favourite multiplayer game and would love to play it with anyone on your list.

I finally got tired of this omission, and created this tool.

## Instructions

1. Create an account on [pushover.net](https://pushover.net/).
2. Create an application on pushover.net.
  * Call it whatever you want, and maybe give it a Steam icon or something.
3. Edit the `config.yml.example` file and save it as `config.yml`.
  * Put your Pushover user and app token in here.
  * You must be able to reach `https://steamcommunity.com/id/<steam_id>/friends/`, so your Steam profile can't be private.
4. Run `stalker.rb`.  Put it in a cronjob or `runit` service or something.
5. Go stalk your Steam friends!

## Notes

To avoid notifying you every time you run this, this tool writes to `last_seen.json` in the current directory.  (If it can't write, it won't send a notification.)

If you get JSON encoding errors, make sure your `LANG` environment variable is set to a Unicode-capable locale (ideally UTF-8).  Some game names contain funny characters.
