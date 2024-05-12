#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'


/*/{Protheus.doc} TRETA013
CADASTRO DE VOLUMES/TANQUES.

@author Totvs TBC
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA013()

Local oBrowse
oBrowse := FWmBrowse():New()
oBrowse:SetAlias( 'ZE6' )
oBrowse:SetDescription( 'Cadastro de Volumes/Tanques' )
oBrowse:Activate()

Return NIL                       

Static function menudef()
              
local aRotina:={}

ADD OPTION aRotina Title 'Visualizar' Action 'VIEWDEF.TRETA013' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Incluir'    Action 'VIEWDEF.TRETA013' OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Alterar'    Action 'VIEWDEF.TRETA013' OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Excluir'    Action 'VIEWDEF.TRETA013' OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Imprimir'   Action 'VIEWDEF.TRETA013'OPERATION 8 ACCESS 0
ADD OPTION aRotina Title 'Copiar'     Action 'VIEWDEF.TRETA013' OPERATION 9 ACCESS 0
ADD OPTION aRotina Title 'Importar dados'     Action 'U_TRETE008()' OPERATION 10 ACCESS 0

Return aRotina    
  
Static function ModelDef()

Local oStruZE6 := FWFormStruct( 1, 'ZE6', /*bAvalCampo*/, /*lViewUsado*/ )
Local oStruZE7 := FWFormStruct( 1, 'ZE7', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'TRETM013', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields( 'ZE6MASTER', /*cOwner*/, oStruZE6 )  
oModel:SetPrimaryKey({"ZE6_FILIAL","ZE6_TABELA"})

// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid( 'ZE7DETAIL', 'ZE6MASTER', oStruZE7, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )  

// Faz relaciomaneto entre os compomentes do model 
  oModel:SetRelation( 'ZE7DETAIL', { { 'ZE7_FILIAL', 'xFilial( "ZE7" )' },{ 'ZE7_CODIGO' , 'ZE6_TABELA'  } } , ZE7->( IndexKey( 1 ) )  )  
//oModel:SetRelation( 'U94DETAIL', { {'U94_FILIAL', 'xFilial( "U94" )'}, {'U94_CODIGO', 'U93_CODIGO'}}, U94->( IndexKey( 1 ) ) )
  
// Liga o controle de nao repeticao de linha
oModel:GetModel( 'ZE7DETAIL' ):SetUniqueLine( { 'ZE7_ITEM' } ) // 'U94_ITEM',

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( 'Definição Medidor Tanque' )

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'ZE6MASTER' ):SetDescription( 'Definição Medidor Tanque' )
oModel:GetModel( 'ZE7DETAIL' ):SetDescription( 'Dados das Medidas (Cm.) x Litros'  )


Return oModel

Static Function ViewDef()
            
// Cria a estrutura a ser usada na View
Local oStruZE6 := FWFormStruct( 2, 'ZE6' )
Local oStruZE7 := FWFormStruct( 2, 'ZE7' )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel( 'TRETA013' )
Local oView

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_ZE6', oStruZE6, 'ZE6MASTER' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid(  'VIEW_ZE7', oStruZE7, 'ZE7DETAIL' )

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'EMCIMA' , 25 )       
oView:CreateHorizontalBox( 'EMBAIXO' , 75 )                      

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_ZE6', 'EMCIMA' )
oView:SetOwnerView( 'VIEW_ZE7', 'EMBAIXO' )

// Liga a identificacao do componente
oView:EnableTitleView( 'VIEW_ZE6' ,'Definição Medidor Tanque')
oView:EnableTitleView( 'VIEW_ZE7', "Dados das Medidas", RGB( 224, 30, 43 ) )

oView:AddIncrementField("VIEW_ZE7","ZE7_ITEM")


oView:SetCloseOnok({||.F.})


Return oView

