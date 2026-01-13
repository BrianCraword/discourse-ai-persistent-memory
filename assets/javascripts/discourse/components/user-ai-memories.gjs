import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";

export default class UserAiMemories extends Component {
  @tracked memories = [];
  @tracked newKey = "";
  @tracked newValue = "";
  @tracked loading = true;

  constructor() {
    super(...arguments);
    this.loadMemories();
  }

  async loadMemories() {
    try {
      const result = await ajax("/ai-persistent-memory");
      this.memories = result.memories || [];
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loading = false;
    }
  }

  @action
  updateNewKey(event) {
    this.newKey = event.target.value;
  }

  @action
  updateNewValue(event) {
    this.newValue = event.target.value;
  }

  @action
  async addMemory() {
    if (!this.newKey || !this.newValue) {
      return;
    }

    try {
      await ajax("/ai-persistent-memory", {
        type: "POST",
        data: { key: this.newKey, value: this.newValue },
      });
      this.memories = [
        ...this.memories,
        { key: this.newKey, value: this.newValue },
      ];
      this.newKey = "";
      this.newValue = "";
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async deleteMemory(key) {
    try {
      await ajax(
        `/ai-persistent-memory/${encodeURIComponent(key)}`,
        {
          type: "DELETE",
        }
      );
      this.memories = this.memories.filter((m) => m.key !== key);
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    <div class="control-group user-ai-memories">
      <label class="control-label">{{i18n "ai_persistent_memory.title"}}</label>
      <p class="desc">{{i18n "ai_persistent_memory.description"}}</p>

      {{#if this.loading}}
        <p>{{i18n "loading"}}</p>
      {{else}}
        {{#if this.memories.length}}
          <table class="memories-table">
            <thead>
              <tr>
                <th>{{i18n "ai_persistent_memory.key"}}</th>
                <th>{{i18n "ai_persistent_memory.value"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.memories as |memory|}}
                <tr>
                  <td><code>{{memory.key}}</code></td>
                  <td>{{memory.value}}</td>
                  <td>
                    <DButton
                      @icon="trash-can"
                      @action={{fn this.deleteMemory memory.key}}
                      class="btn-danger btn-small"
                    />
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          <p class="no-memories">{{i18n "ai_persistent_memory.empty"}}</p>
        {{/if}}

        <div class="add-memory">
          <h4>{{i18n "ai_persistent_memory.add_new"}}</h4>
          <div class="memory-form">
            <input
              type="text"
              value={{this.newKey}}
              placeholder={{i18n "ai_persistent_memory.key_placeholder"}}
              class="memory-key-input"
              {{on "input" this.updateNewKey}}
            />
            <input
              type="text"
              value={{this.newValue}}
              placeholder={{i18n "ai_persistent_memory.value_placeholder"}}
              class="memory-value-input"
              {{on "input" this.updateNewValue}}
            />
            <DButton
              @label="ai_persistent_memory.save"
              @action={{this.addMemory}}
              class="btn-primary"
            />
          </div>
        </div>
      {{/if}}
    </div>
  </template>
}
