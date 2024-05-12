#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETA012
Cadastro de tanques físicos utilizando MVC 

@author Pablo Cavalcante
@since 26/10/2018

@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA012()

Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'ZE0' )
	oBrowse:SetDescription( 'Cadastro de Tanques Fisicos' )
	
	oBrowse:Activate()

Return NIL


//-------------------------------------------------------------------
Static Function MenuDef()   

Local aRotina := {}
	
	ADD OPTION aRotina Title 'Pesquisar'   Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  Action 'VIEWDEF.TRETA012' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'     Action 'VIEWDEF.TRETA012' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     Action 'VIEWDEF.TRETA012' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     Action 'VIEWDEF.TRETA012' 	OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    Action 'VIEWDEF.TRETA012' 	OPERATION 08 ACCESS 0
	ADD OPTION aRotina Title 'Copiar'      Action 'VIEWDEF.TRETA012' 	OPERATION 09 ACCESS 0  

Return aRotina


//-------------------------------------------------------------------
Static Function ModelDef()

Local oStruZE0 := FWFormStruct( 1, 'ZE0', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM012', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
	
	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'ZE0MASTER', /*cOwner*/, oStruZE0 )
	
	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Tanques Fisicos' )
	
	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "ZE0_FILIAL" , "ZE0_TANQUE" })
	
	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'ZE0MASTER' ):SetDescription( 'Dados do Tanque Fisico' )

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oStruZE0 := FWFormStruct( 2, 'ZE0' )

// Cria a estrutura a ser usada na View
Local oModel   := FWLoadModel( 'TRETA012' )

Local oView

	// Cria o objeto de View
	oView := FWFormView():New()
	
	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )
	
	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_ZE0', oStruZE0, 'ZE0MASTER' )
	
	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )
	
	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_ZE0', 'SUPERIOR' )
	
	// Liga a identificacao do componente
	oView:EnableTitleView('VIEW_ZE0','Dados do Tanque Fisico')   
	
	// Define fechamento da tela
	oView:SetCloseOnOk( {||.T.} )

Return oView 