# Hooks to attach to the Redmine Issues.
class RedmineImLinkHook < Redmine::Hook::Listener
  def controller_issues_edit_before_save(context = {})
    issue = context[:issue]

    add_current_user(issue)
    add_assignee(issue)
    add_assigned_was(issue)
  end

  def controller_issues_new_before_save(context = {})
    add_current_user(context[:issue])
    add_assignee(context[:issue])
  end


  def controller_issues_bulk_edit_before_save(context = {})
    issue = context[:issue]

    add_current_user(issue)
    add_assignee(issue)
    add_assigned_was(issue)
  end


  private
  def add_current_user(issue)
    add_watcher_to_issue(issue, User.current)
  end

  def add_assignee(issue)
    add_watcher_to_issue(issue, issue.assigned_to)
  end

  def add_assigned_was(issue)
    if issue.assigned_to_was
      add_watcher_to_issue(issue, issue.assigned_to_was);
    end
  end

  def add_watcher_to_issue(issue, assignee)
  
	addwatchers = Setting.plugin_redmine_im_link['addwatchers'].to_s.eql?('true') ? true : false
  
    return if assignee.nil? || !assignee.is_a?(User) || assignee.anonymous? || !assignee.active? || !addwatchers

    issue.add_watcher(assignee) unless issue.watched_by?(assignee)
  end
  
end



class IncludeJavascriptsHook < Redmine::Hook::ViewListener
    include ActionView::Helpers::TagHelper

    def view_layouts_base_html_head(context)
      javascript_include_tag(:redmine_im_link, :plugin => 'redmine_im_link')
    end
end

  
