# frozen_string_literal: true

# name: discourse-ai-persistent-memory
# about: Allows users to manage persistent AI memory key/value pairs in preferences
# version: 0.1.0
# authors: crawf
# url: https://github.com/discourse/discourse

enabled_site_setting :ai_persistent_memory_enabled

register_asset "stylesheets/ai-memories.scss"

module ::DiscourseAiPersistentMemory
  PLUGIN_NAME = "discourse-ai-persistent-memory"
end

require_relative "lib/discourse_ai_persistent_memory/engine"

after_initialize do
  require_relative "app/controllers/discourse_ai_persistent_memory/memories_controller"
  require_relative "lib/discourse_ai_persistent_memory/tool_runner_extension"

  Discourse::Application.routes.append do
    mount DiscourseAiPersistentMemory::Engine, at: "/ai-persistent-memory"
  end

  # Patch ToolRunner to add memory functions if discourse-ai is loaded
  if defined?(DiscourseAi::Personas::ToolRunner)
    DiscourseAi::Personas::ToolRunner.prepend(DiscourseAiPersistentMemory::ToolRunnerExtension)

    # Patch the mini_racer_context method to include attach_memory call
    DiscourseAi::Personas::ToolRunner.class_eval do
      alias_method :original_mini_racer_context, :mini_racer_context

      def mini_racer_context
        @mini_racer_context ||=
          begin
            ctx = original_mini_racer_context
            # attach_memory is now provided by our extension via prepend
            ctx
          end
      end

      # Patch framework_script to include memory JS object
      alias_method :original_framework_script, :framework_script

      def framework_script
        original_script = original_framework_script
        memory_js = DiscourseAiPersistentMemory::ToolRunnerExtension::MEMORY_JS
        # Insert memory JS before the context line
        original_script.sub("const context =", "#{memory_js}\n        const context =")
      end
    end
  end
end
