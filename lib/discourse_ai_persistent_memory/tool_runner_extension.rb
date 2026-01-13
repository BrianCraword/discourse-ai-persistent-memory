# frozen_string_literal: true

module DiscourseAiPersistentMemory
  module ToolRunnerExtension
    def attach_memory(mini_racer_context)
      mini_racer_context.attach(
        "_memory_set",
        ->(key, value) do
          in_attached_function do
            user_id = @context.user&.id
            return { error: "No user context" } unless user_id
            return { error: "Key required" } if key.blank?

            namespace = "ai_user_memory_#{user_id}"
            PluginStore.set(namespace, key.to_s, value)
            { success: true, key: key }
          end
        end,
      )

      mini_racer_context.attach(
        "_memory_get",
        ->(key) do
          in_attached_function do
            user_id = @context.user&.id
            return nil unless user_id

            namespace = "ai_user_memory_#{user_id}"
            PluginStore.get(namespace, key.to_s)
          end
        end,
      )

      mini_racer_context.attach(
        "_memory_list",
        ->() do
          in_attached_function do
            user_id = @context.user&.id
            return [] unless user_id

            namespace = "ai_user_memory_#{user_id}"
            PluginStoreRow
              .where(plugin_name: namespace)
              .pluck(:key, :value)
              .map { |k, v| { "key" => k, "value" => v } }
          end
        end,
      )

      mini_racer_context.attach(
        "_memory_delete",
        ->(key) do
          in_attached_function do
            user_id = @context.user&.id
            return { error: "No user context" } unless user_id

            namespace = "ai_user_memory_#{user_id}"
            PluginStore.remove(namespace, key.to_s)
            { success: true }
          end
        end,
      )
    end

    MEMORY_JS = <<~JS
      const memory = {
        set: function(key, value) {
          const result = _memory_set(key, typeof value === 'object' ? JSON.stringify(value) : String(value));
          if (result && result.error) throw new Error(result.error);
          return result;
        },
        get: function(key) {
          const result = _memory_get(key);
          if (!result) return null;
          try { return JSON.parse(result); } catch { return result; }
        },
        list: function() { return _memory_list(); },
        delete: function(key) {
          const result = _memory_delete(key);
          if (result && result.error) throw new Error(result.error);
          return result;
        }
      };
    JS
  end
end
