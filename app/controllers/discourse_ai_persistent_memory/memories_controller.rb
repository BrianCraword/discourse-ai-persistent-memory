# frozen_string_literal: true

module DiscourseAiPersistentMemory
  class MemoriesController < ::ApplicationController
    requires_plugin DiscourseAiPersistentMemory::PLUGIN_NAME
    requires_login

    def index
      memories = fetch_user_memories
      render json: { memories: memories }
    end

    def create
      key = params.require(:key)
      value = params.require(:value)

      namespace = "ai_user_memory_#{current_user.id}"
      PluginStore.set(namespace, key, value)

      render json: { success: true, key: key, value: value }
    end

    def destroy
      key = params[:key]
      return render json: { error: "Key required" }, status: 400 if key.blank?

      namespace = "ai_user_memory_#{current_user.id}"
      PluginStore.remove(namespace, key)

      head :no_content
    end

    private

    def fetch_user_memories
      namespace = "ai_user_memory_#{current_user.id}"
      PluginStoreRow
        .where(plugin_name: namespace)
        .pluck(:key, :value)
        .map { |k, v| { key: k, value: v } }
    end
  end
end
