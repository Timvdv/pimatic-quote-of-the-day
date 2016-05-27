# pimatic-quote-of-the-day
Creates a variable with the quote of the day

Add the plugin:
```
    {
      "plugin": "quote-of-the-day"
    }
```

Add the quote device:
```
    {
      "id": "quote",
      "name": "quote of the day",
      "quote": "",
      "class": "QuoteDevice"
    }
```

#Update the quote device
To update the quote device I used the default scheduler build into Pimatic
When you add this line to your rules the quote device gets updated when it's
03:00 in the morning.
```
when its 03:00 update quote quote with "quote"
```
