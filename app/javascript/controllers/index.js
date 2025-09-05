import { Application } from "@hotwired/stimulus";
export const application = Application.start();

import Notification from "@stimulus-components/notification";
application.register("notification", Notification);

import CharacterCounter from "@stimulus-components/character-counter";
application.register("character-counter", CharacterCounter);

import { Dropdown, Tabs } from "tailwindcss-stimulus-components";
application.register("dropdown", Dropdown);
application.register("tabs", Tabs);
