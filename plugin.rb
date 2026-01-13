# frozen_string_literal: true

# name: discourse-ai-persistent-memory
# about: Allows users to manage persistent AI memory key/value pairs in preferences
# version: 0.2.0
# authors: crawf
# url: https://github.com/BrianCraword/discourse-ai-persistent-memory

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
  end
end
