class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :popular, :latest, :filter, :search]
  before_action :find_course, only: [:edit, :update, :destroy, :enroll, :like, :unlike, :fork]
  before_action :ensure_user_access, only: [:edit, :update, :destroy]

  def index
    @title = 'Latest courses on CourseHub'
    @courses = Course.all
  end

  def show
    @course = Course.includes(:course_progresses, :course_items).find(params[:id])
    if user_signed_in?
      @progress = CourseProgress.
        where(course_id: @course.id, user_id: current_user.id).first
    end
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      @course.tags = course_tags
      flash[:notice] = 'New course was successfully created'
      redirect_to courses_path
    else
      render :new
    end
  end

  def fork
    course = @course.fork(current_user.id)
    redirect_to course_path(course)
  end

  def edit
  end

  def update
    if @course.update(course_params)
      @course.tags = course_tags
      flash[:notice] = 'Course was successfully updated'
      redirect_to course_path(params[:id])
    else
      render :edit
    end
  end

  def destroy
    @course.delete
    redirect_to courses_path
  end

  def own
    @title = 'Your own courses'
    @courses = current_user.courses
    render :index
  end

  def learning
    @progresses = CourseProgress.includes(:course).where(user: current_user)
  end

  def popular
    @title = 'Most popular courses'
    @courses = (Course.all.sort_by { |x| x.likes.size }).reverse
    render :index
  end

  def latest
    @title = 'Latest courses'
    @courses = Course.order_by(:created_at => 'desc')
    render :index
  end

  def enroll
    current_user.enroll(@course)
    flash[:notice] = "You've successfully enrolled in this course"
    redirect_to course_path(@course)
  end

  def like
    @course.like(current_user.id)
    render json: {result: 'ok', likes: @course.likes.size}
  end

  def unlike
    @course.unlike(current_user.id)
    render json: {result: 'ok', likes: @course.likes.size}
  end

  def filter
    tag = Tag.where(name: params[:tag]).first
    @title = "Courses with tag #{tag.name}"
    @courses = tag && tag.courses || []
    render :index
  end

  def search
    @title = "Search for: #{params[:search]}"
    keywords = params[:search].strip.downcase.split(/\s+/)
    @courses = Course.all.select do |course| 
      keywords.find do 
        |keyword| course.name.downcase.include?(keyword) || course.description.include?(keyword)
      end
    end
    render :index
  end

  protected

  def course_params
    params.require(:course).permit(:name, :description).
      merge(user: current_user)
  end

  def course_tags
    params[:course][:tags_names].strip.split(',')
  end

  def ensure_user_access
    unless @course && @course.user_id == current_user.id
      flash[:alert] = 'You can not edit this course'
      redirect_to(:back)
    end
  end

  def find_course
    @course = Course.find(params[:id])
  end
end
