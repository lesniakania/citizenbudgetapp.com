ActiveAdmin.register Section do
  belongs_to :questionnaire

  # CanCan has trouble with embedded documents, so we may need to load and
  # authorize resources manually. In this case, we will authorize against
  # the top-level document.
  # @see https://github.com/ryanb/cancan/issues/319
  #
  # Since sections are scoped to the parent questionnaire, we don't necessarily
  # need to use #accessible_by to enforce constraints.
  #
  # https://github.com/ryanb/cancan/wiki/Controller-Authorization-Example
  controller do
    cache_sweeper :questionnaire_sweeper, only: [:create, :update, :destroy]

    skip_authorize_resource :only => :index

    def index
      authorize! :show, parent
      index!
    end
  end

  index download_links: false do
    column :title
    column :group do |s|
      t(s.group, scope: :group) if s.group?
    end
    column :questions do |s|
      s.questions.count
    end
    default_actions
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :group, collection: Section::GROUPS.map{|g| [t(g, scope: :group), g]}
      f.input :description, as: :text, input_html: {rows: 3}
      f.input :extra, as: :text, input_html: {rows: 3}
      f.input :embed, as: :text, input_html: {rows: 3}
    end

    f.has_many :questions, header: 'Services and activities' do |g|
      unless g.object.new_record?
        g.input :_destroy, as: :boolean
      end
      g.input :title
      g.input :description, as: :text, input_html: {rows: 3}
      g.input :extra, as: :text, input_html: {rows: 3}
      g.input :widget, collection: Question::WIDGETS.map{|w| [t(w, scope: :widget), w]}
      g.input :options_as_list, as: :text, input_html: {rows: 5}
      g.input :default_value, input_html: {size: 8}
      g.input :minimum_units, input_html: {size: 8}
      g.input :maximum_units, input_html: {size: 8}
      g.input :step, input_html: {size: 8}
      g.input :unit_name, input_html: {size: 20}
      g.input :unit_amount, as: :string, input_html: {size: 8}
      g.input :required
      g.input :position, as: :hidden
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :group do |s|
        t(s.group, scope: :group) if s.group?
      end
      row :description do |s|
        RDiscount.new(s.description).to_html.html_safe if s.description?
      end
      row :extra do |s|
        RDiscount.new(s.extra).to_html.html_safe if s.extra?
      end
      row :embed do |s|
        s.embed.html_safe if s.embed?
      end
      row :questions do |s|
        if s.questions.present?
          ul(class: can?(:update, s) ? 'sortable' : '') do
            s.questions.each do |q|
              li(id: dom_id(q)) do
                if can?(:update, q)
                  i(class: 'icon-move')
                end
                text_node q.title
              end
            end
          end
        end
      end
    end
  end

  member_action :sort, method: :post do
    resource.questions.each do |q|
      q.update_attribute :position, params[:question].index(q.id.to_s)
    end
    render nothing: true, status: 204
  end
end
