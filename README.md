# sf-feature-flags

Easily add Feature Flags to your code, and allow admins to turn toggle features on and off, at the user, profile, and org levels.

## Introduction

Feature Flags are a way of allowing admins to easily enable/disable features, both for the org as a whole, and for individual users or profiles. This is very useful for a number of different use cases:

-   "Dark" Deployments. Push code to production, but leave the feature disabled. Allows for CI/CD workflows, without disrupting users.
-   Phased Rollouts. Disable a new feature globally, but turn it on for specific users or profiles.
-   Debugging. Toggle specific features on/off, to determine which feature(s) might be causing problems.
-   Data Loads. Turn off specific automations (or whole groups of automations) for a specific user, while that user is doing mass data operations.

## How it Works

The Feature Flag system consists of three key components:

1. The Feature Flag custom metadata object.
2. The User Feature Flag custom setting.
3. The `Flags` class.

### `Feature_Flag__mdt` (Custom Metadata Object)

This is where you, as a developer or admin, register each new feature.

When building the feature, you will create a Feature Flag record, and give it a unique Code. You'll then use that Feature Flag Code in your Apex function or your Process Builder or Flow, to check whether the feature should run or not for the given user.

In addition to the Code, each feature should also be given a Category (Trigger, Flow, Process Builder, Other) and, if applicable, an Object API Name, if the feature is specific to one Object (as all Triggers, and most PBs and Flows are). In addition to these values, there is an "Enabled" checkbox, that determines whether the feature is Enabled by default. There is also an optional "Other Settings" text field, where additional data can be stored -- this is expected to be a JSON object, but can contain whatever sort of data you want to use in your feature code.

### `User_Feature_Flag__c` (Hierarchical Custom Setting Object).

This is a _Hierarchical_ custom setting, and is designed to let specific Users or whole Profiles _override_ the "Enabled" setting of the given feature. By creating a User Feature Flag record for a given user, you can change system behavior for that user alone.

There are 4 fields on this object: Category Opt IN, Category Opt OUT, Feature Opt IN, Feature Opt OUT.

The Feature Opt IN/OUT field take a comma-separated list of unique Feature Flag Codes. If a specific Feature Flag is disabled, but the user's Feature Opt IN field contains that code, then the feature is enabled for that user. Likewise, if the Feature is Enabled, but the Feature Opt OUT field contains that code, then the feature is disabled for that user.

The Category Opt IN/OUT fields do the same thing, but operate on whole classes of features. For example, by entering "T" into the Category Opt OUT field would disable ALL triggers (as long as they are coded to respect the Feature Flag system). By entering "T.Opportunity,P.Account,F", you would disable all triggers on the Opportunity, all Process Builders on the Account, and all Flows (again, for those triggers, process builder, and flows, that are built to utilize the Feature Flag system).

### `Flags` (Apex Class)

This class, which provides an easy way of checking whether or not your feature should run.

The `Flags` class has a `check()` method that can accept EITHER 1) a single Code string, or 2) a combination of Category and optional Object. When implementing a specific feature witha code, you'll usually just pass the Code string, and get back a result which includes a Boolean `enabled`, and a String `explanation`. When `enabled` is TRUE, you should continue to run your feature code; when FALSE, you should exit your code, and optionally log the explanation string.

In addition to the `Flags` class, there is an `InvFlags` invocable class, which exposes the same functionality to Process Builders and Flows, making it simple to incorporate the Feature Flag logic into those automations.

## Conclusion

With the Feature Flags system, developers and admins have an easy and consistent way of creating and using flags to enable or disable pieces of functionality.  You should now understand how to create new flags when building features, how to enable/disable those feature flags for the system as a whole, as well as for individual profiles and users, and how to determine whether or not to use a particular feature in your Apex code, Process Builders, or Flows.