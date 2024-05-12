#INCLUDE "PARMTYPE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} TRETA029
Cadastro de Tipo de Preço Base.

@author pablo
@since 17/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA029()

Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'U0A' )
	oBrowse:SetDescription( 'Tipo de Preço Base' )
	oBrowse:Activate()
	
Return

/*/{Protheus.doc} MenuDef

@author pablo
@since 17/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MenuDef()     

Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisar'   		Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  		Action 'VIEWDEF.TRETA029' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'     		Action 'VIEWDEF.TRETA029' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     		Action 'VIEWDEF.TRETA029' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     		Action 'VIEWDEF.TRETA029' 	OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    		Action 'VIEWDEF.TRETA029' 	OPERATION 08 ACCESS 0 
	//ADD OPTION aRotina Title 'Copiar'     		Action 'VIEWDEF.TRETA029' 	OPERATION 09 ACCESS 0

	//PE para add nova opções
	If ExistBlock("TRA029MN")
		aRotina := ExecBlock("TRA029MN",.F.,.F.,aRotina)
	Endif

Return aRotina

/*/{Protheus.doc} ModelDef

@author pablo
@since 17/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ModelDef()

Local oStruU0A := FWFormStruct( 1, 'U0A', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

	oStruU0A:RemoveField( 'U0A_FILIAL' )

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM029', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
	
	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'U0AMASTER', /*cOwner*/, oStruU0A )
	
	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Tipo de Preço Base' )
	
	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U0A_FILIAL" , "U0A_FORPAG" , "U0A_CONDPG" , "U0A_ADMFIN" })
	
	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'U0AMASTER' ):SetDescription( 'Tipo de Preço Base' )

Return oModel

/*/{Protheus.doc} ViewDef

@author pablo
@since 05/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ViewDef()

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oStruU0A := FWFormStruct( 2, 'U0A' )

// Cria a estrutura a ser usada na View
Local oModel   := FWLoadModel( 'TRETA029' )

Local oView

	// Cria o objeto de View
	oView := FWFormView():New()
	
	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )
	
	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U0A', oStruU0A, 'U0AMASTER' )
	
	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )
	
	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_U0A', 'SUPERIOR' )
	
	// Liga a identificacao do componente
	//oView:EnableTitleView('VIEW_U0A','Tipo de Preço Base')   
	
	// Define fechamento da tela
	//oView:SetCloseOnOk( {||.T.} )

Return oView
