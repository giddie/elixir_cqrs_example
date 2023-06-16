# Elixir CQRS Example

This project is intended as a reference for patterns that are useful when
implementing event-driven and CQRS architectures in Elixir.

## What is this?

It's a [Phoenix](https://www.phoenixframework.org/) app implementing a simple
set of requirements, split into branches where each branch uses a different
approach or architectural pattern.

The implemented behaviour models a simple warehouse containing products, where
each product has an associated quantity. The requirements have been sketched out
using an [Event Modelling](https://eventmodeling.org/) diagram that should
appear below:

![Event Model](/design/event-model.png?raw=true)

## Motivation

My feeling when approaching the topics of event-driven systems, CQRS, and
event streaming, is that they're often all bundled together, and sometimes
presented in the form of an opinionated framework. But I don't think these
patterns call for a framework. And they don't need to be complex in their
implementation. For that reason, although I commend the efforts of projects
such as [Commanded](https://hexdocs.pm/commanded), they tend to enforce a very
particular architectural vision for a project, and I think that can sometimes
lead to more confusion, because it can appear a bit magic.

My intention is to instead produce building blocks that can be freely dropped
into place and modified to suit whatever a project's requirements are.

## Structure

Each branch of the repository takes a different approach to solving the
requirements. I may well rebase branches from time to time, if it helps me keep
things organised.

### Running

Each branch should be quite straight-forward to run on your own machine. There's
a `docker-compose.yml` file on some branches, which can be used to spin up
dependencies and tools, such as Postgres, RabbitMQ, or PgAdmin:

If you have [direnv](https://direnv.net/) installed, it'll source `.env.dev` for
you. Otherwise, you can do it manually after inspecting the file:

```bash
$ cat .env.dev
$ source .env.dev
```

And then:

```bash
$ docker-compose up
$ mix deps.get
$ PHX_SERVER=true iex -S mix
```


Once you're done, you may want to clear up any unneeded docker volumes:

```bash
$ docker volume ls
$ docker volume rm ...
```

### Branches

Jump to each branch's README to see branch-specific walkthroughs and design
explanations.

| Branch | Content |
| - | - |
| [memory-sync](https://github.com/giddie/elixir_cqrs_example/tree/memory-sync) | State is stored in memory, and all commands and events are processed synchronously. This is probably the simplest approach. |
| [persisted-sync](https://github.com/giddie/elixir_cqrs_example/tree/persisted-sync) | State is stored in a Postgres database, but all commands and events are still processed synchronously. |
| [persisted-async](https://github.com/giddie/elixir_cqrs_example/tree/persisted-async) | State is stored in a Postgres database, and RabbitMQ is used as a message broker. Most processing is now asynchronous, adding a bit more complexity. |

## Vertical Slice Architecture

I like to group code by functionality, rather than by architecture. For
instance, the URL `/warehouse/products` is routed to a dedicated controller
at `lib/cqrs_example/warehouse/views/products/web_controller.ex`. This has the
advantage that when refactoring or removing a particular feature, you don't need
to go hunting across multiple layers of architecture in different directories.
In most cases, removing a directory is almost all that's needed.

## Further Considerations

In a production system, events should be **idempotent**, meaning that it should
not matter if they're processed twice. This could happen, for instance, due to a
transient failure resulting in a retry. The events in this design are not
particularly well-designed for this. A better approach may be to also include
the current quantity in the event payloads, offering a sanity check to the event
handler. But this would also have removed most of the need for tracking state at
all, so for the sake of the example, I kept these events simplistic.

## Thanks

Many thanks to Derek Comartin
([CodeOpinion](https://www.youtube.com/@CodeOpinion))'s invaluable learning
resources. I've found them incredibly instructive and helpful in gaining a
thorough understanding of these topics.
