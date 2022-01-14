# frozen_string_literal: true

class TreeEntryPresenter < Gitlab::View::Presenter::Delegated
  presents nil, as: :tree

  def web_url
    Gitlab::Routing.url_helpers.project_tree_url(tree.repository.project, File.join(tree.commit_id, tree.path))
  end

  def web_path
    Gitlab::Routing.url_helpers.project_tree_path(tree.repository.project, File.join(tree.commit_id, tree.path))
  end
end
