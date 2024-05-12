#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETA045
Cadastro de Motivo de Devolução utilizando MVC

@author Pablo Cavalcante Nunes
@since 26/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA045()

Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias( 'U0F' )
oBrowse:SetDescription( 'Motivo de Devolução' )

oBrowse:Activate()

Return NIL


//-------------------------------------------------------------------
Static Function MenuDef()     

Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisar'   		Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  		Action 'VIEWDEF.TRETA045' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'     		Action 'VIEWDEF.TRETA045' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     		Action 'VIEWDEF.TRETA045' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     		Action 'VIEWDEF.TRETA045' 	OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    		Action 'VIEWDEF.TRETA045' 	OPERATION 08 ACCESS 0
	ADD OPTION aRotina Title 'Copiar'      		Action 'VIEWDEF.TRETA045' 	OPERATION 09 ACCESS 0  

Return aRotina


//-------------------------------------------------------------------
Static Function ModelDef()

Local oStruU0F := FWFormStruct( 1, 'U0F', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM045', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'U0FMASTER', /*cOwner*/, oStruU0F )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Motivo de Devolução' )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U0F_FILIAL" , "U0F_CODIGO" })

	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'U0FMASTER' ):SetDescription( 'Motivo' )

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oStruU0F := FWFormStruct( 2, 'U0F' )

// Cria a estrutura a ser usada na View
Local oModel   := FWLoadModel( 'TRETA045' )

Local oView

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U0F', oStruU0F, 'U0FMASTER' )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_U0F', 'SUPERIOR' )

	// Liga a identificacao do componente
	oView:EnableTitleView('VIEW_U0F','Motivo')   

	// Define fechamento da tela
	oView:SetCloseOnOk( {||.T.} )

Return oView
