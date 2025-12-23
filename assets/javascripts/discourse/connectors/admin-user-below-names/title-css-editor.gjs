import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";

export default class TitleCssEditor extends Component {
  @service currentUser;
  @service dialog;
  @tracked editing = false;
  @tracked buffer = "";
  @tracked saving = false;

  constructor() {
    super(...arguments);
    this.buffer = this.args.outletArgs.user.custom_fields?.title_css || "";
  }

  get canEdit() {
    return this.currentUser?.staff;
  }

  @action
  startEdit(event) {
    event?.preventDefault();
    this.buffer = this.args.outletArgs.user.custom_fields?.title_css || "";
    this.editing = true;
  }

  @action
  cancelEdit(event) {
    event?.preventDefault();
    this.editing = false;
    this.buffer = this.args.outletArgs.user.custom_fields?.title_css || "";
  }

  @action
  updateBuffer(event) {
    this.buffer = event.target.value;
  }

  @action
  async save() {
    this.saving = true;
    try {
      const result = await ajax(
        `/admin/users/${this.args.outletArgs.user.id}/title-css`,
        {
          type: "PUT",
          data: { title_css: this.buffer },
        }
      );

      // Update the model with sanitized value
      if (!this.args.outletArgs.user.custom_fields) {
        this.args.outletArgs.user.custom_fields = {};
      }
      this.args.outletArgs.user.custom_fields.title_css = result.title_css;

      this.editing = false;

      if (result.sanitized) {
        // Notify user that CSS was sanitized
        this.dialog.alert(i18n("user_fancy_titles.css_was_sanitized"));
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    {{#if this.canEdit}}
      <div class="display-row title-css-field">
        <div class="field">{{i18n "user_fancy_titles.title_css_label"}}</div>
        <div class="value">
          {{#if this.editing}}
            <textarea
              value={{this.buffer}}
              {{on "input" this.updateBuffer}}
              rows="3"
              placeholder={{i18n "user_fancy_titles.title_css_placeholder"}}
              class="title-css-input"
            ></textarea>
          {{else}}
            <a href {{on "click" this.startEdit}} class="inline-editable-field">
              {{#if @outletArgs.user.custom_fields.title_css}}
                <code>{{@outletArgs.user.custom_fields.title_css}}</code>
              {{else}}
                <span class="empty-value">{{i18n
                    "user_fancy_titles.no_custom_css"
                  }}</span>
              {{/if}}
            </a>
          {{/if}}
        </div>
        <div class="controls">
          {{#if this.editing}}
            <DButton
              class="btn-primary"
              @action={{this.save}}
              @label="save"
              @disabled={{this.saving}}
            />
            <a href {{on "click" this.cancelEdit}}>{{i18n "cancel"}}</a>
          {{else}}
            <DButton
              class="btn-default"
              @action={{this.startEdit}}
              @icon="pencil"
            />
          {{/if}}
        </div>
      </div>
      <div class="display-row title-css-help">
        <div class="field"></div>
        <div class="value">
          <p class="help">{{i18n "user_fancy_titles.allowed_properties"}}</p>
        </div>
        <div class="controls"></div>
      </div>
    {{/if}}
  </template>
}
