---
title: Adding support for out-of-order migrations
---

Starting with `goose` [v3.3.0](https://github.com/pressly/goose/releases/tag/v3.3.0) we added the ability to apply missing (out-of-order) migrations. Thanks for all the the community feedback over the years.

Let's back it up, what are "missing" or "out-of-order" migrations?

Suppose migration 1 and 4 are applied and then 2, 3, 5 are introduced. Prior to [v3.3.0](https://github.com/pressly/goose/releases/tag/v3.3.0) `goose` would ignore migrations 2, 3 and apply only 5. Although this might seem odd, this is fairly consistent behaviour with other migration tools.

However, many users were not satisfied with this behaviour, summarized as:

- migrations 2 and 3 are "silently" ignored
- unable to apply migrations 2 and 3 if newer versions have already been applied. To paraphrase this [comment](https://github.com/pressly/goose/issues/172#issuecomment-493645187):

> *I would very much prefer just to apply Bill's migration and call it a day.*

This comment from [`@zmoazeni`](https://github.com/zmoazeni) has stuck with me over the years.

---

Internally within Pressly (acquired by [Alida](https://www.alida.com/)) we suggested adopting the [hybrid versioning approach](https://github.com/pressly/goose#hybrid-versioning). Briefly, in development developers create ***timestamped*** migrations, and subsequently when that PR is merged into the `main` branch its converted into a ***sequential*** migration. 

Then when a release is cut and rolled out to production only sequential migrations are applied. It was a process solution to the problem that worked for our team. Yes, yes.. this does require developers to be rebasing and resolving conflicts (if any) between migrations.

<figure markdown="1">
![hybrid versioning approach](../assets/hybrid-versioning-approach.png){ width=550px; }
</figure>

Buttttt..... as we listened to community feedback, and saw the rise in the number of `goose` forks (mainly to support missing migrations) we decided to do something about it.

From this [comment](https://github.com/pressly/goose/issues/262#issue-960391249):

> We should meet users in the middle (lots of great feedback from the community) and give them the flexibility to use `goose` as they see fit. The responsibility will be shifted from the tool itself, to the end user.

Here we are, this is how it works today.

By default, if you attempt to apply missing (out-of-order) migrations `goose` will raise an error. However, if you want to apply these missing migrations pass `goose` the `-allow-missing` flag, or if using as a library supply the functional option `goose.WithAllowMissing()` to Up, UpTo or UpByOne.

More details can be found in the [Changelog here](https://github.com/pressly/goose/releases/tag/v3.3.0) and the [tracking issue #262](https://github.com/pressly/goose/issues/262).

Hope folks find this useful. More awesome things are planned for `goose` 🚀.

ps. consider dropping [pressly/goose](https://github.com/pressly/goose) a ⭐️ if you find this package useful.