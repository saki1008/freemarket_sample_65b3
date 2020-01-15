class ItemsController < ApplicationController
  before_action :specific_item, only: [:show]
  def index
    @items_ladies = Item.adjust.active(1)
    @items_mens = Item.adjust.active(212)
    @items_toies = Item.adjust.active(794)
    @items_electricdevices = Item.adjust.active(907)
  
  end

  def new    
    @item = Item.new
    @item.images.new
    @category_parent_array = []
    parent_origin = [value: 0, name: "---"]
    @category_parent_array << parent_origin

    Category.where(ancestry: nil).each do |parent|
      parent = [value: parent.id, name: parent.name]
      @category_parent_array << parent
    end
  end



  def create
    @item = Item.new(item_params)
    @item.seller_id = current_user.id
    if @item.save
      redirect_to root_path
    else
      redirect_to new_item_path
    end
  end
  
  def show
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
    #出品者のその他の出品
    @item_seller_id = Item.adjust.limit(9).where(seller_id: @item.seller_id)
    #あなたの出品一覧
    @items_seller_id = Item.where(seller_id:current_user.id).adjust.limit(9)
    @item= Item.find(params[:id])
  end


  def edit
    @category_parent_array = []
    parent_origin = [value: 0, name: "---"]
    @category_parent_array << parent_origin

    Category.where(ancestry: nil).each do |parent|
      parent = [value: parent.id, name: parent.name]
      @category_parent_array << parent
    end
  end


  def update
    if @item.update(item_params)
      redirect_to root_path
    else
      render :edit
    end
  end

  def destroy
    @item= Item.find(params[:id])
    if @item.destroy
      # 削除に成功した時の処理
      redirect_to root_path
    else
      # 削除に失敗した時の処理
      redirect_to root_path, alert: "削除が失敗しました"
    end
    
  end
  
  def edit
    @item = Item.find(params[:id])
    @item.images.build
    @addresses = Address.all
    @root_category = @item.category
    @child_category = Category.find(@item.child_category)
    @grandchild_category = Category.find(@item.grandchild_category)

    render layout: 'index'
  end



  def get_category_children
    @category_children = Category.find(params[:parent_id]).children
    respond_to do |format|
      format.json
    end
  end
  
  def get_category_grandchildren
    @category_grandchildren = Category.find(params[:child_id]).children
    respond_to do |format|
      format.json
    end
  end

  def buy
    @user = User.find(params[:id])
    @item = Item.find(params[:id])
    @address = Address.find(params[:id])
    card = Card.where(user_id: current_user.id).first
    #Cardテーブルは前回記事で作成、テーブルからpayjpの顧客IDを検索
    if card.blank?
      #登録された情報がない場合にカード登録画面に移動
      redirect_to controller: "card", action: "new"
    else
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      #保管した顧客IDでpayjpから情報取得
      customer = Payjp::Customer.retrieve(card.customer_id)
      #保管したカードIDでpayjpから情報取得、カード情報表示のためインスタンス変数に代入
      @default_card_information = customer.cards.retrieve(card.card_id)
    end
  end

  def pay
    @item= Item.find(params[:id])
    card = Card.where(user_id: current_user.id).first
    Payjp.api_key = ENV['PAYJP_PRIVATE_KEY']
    Payjp::Charge.create(
    :amount => @item.price, #支払金額を入力（itemテーブル等に紐づけても良い）
    :customer => card.customer_id, #顧客ID
    :currency => 'jpy', #日本円
  )
  redirect_to action: 'done' #完了画面に移動
  end

  def done
    Item.update(params[:id],status: 1)
  end

end

  private
  def item_params
    params.require(:item).permit(:name, :price, :description, :condition, :delivery_charge, :delivery_area, :delivery_days, :category_id, :child_category, :grandchild_category, images_attributes: [:src, :_destroy]).merge(seller_id:current_user.id)
  end


  def specific_item
    @item = Item.find(params[:id])
  end


  def item_param
    params.require(:item).permit(
      :name,
      :text,
      :price,
      #この辺の他コードは関係ない部分なので省略してます
    ).merge(user_id: current_user.id)
  end

