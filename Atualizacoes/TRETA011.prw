#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETA011
Cadastro de concentradoras utilizando MVC

@author Wellington Gonçalves
@since 19/05/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA011()

Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias( 'MHX' )
oBrowse:SetDescription( 'Cadastro de Concentradoras' )

// adiciona legenda no Browser
oBrowse:AddLegend( "MHX_STATUS == '1'", "GREEN", "Ativado")
oBrowse:AddLegend( "MHX_STATUS == '2'", "RED"  , "Desativado")

oBrowse:Activate()

Return NIL


//-------------------------------------------------------------------
Static Function MenuDef()     

Local aRotina := {}

	ADD OPTION aRotina Title 'Pesquisar'   		Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  		Action 'VIEWDEF.TRETA011' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'     		Action 'VIEWDEF.TRETA011' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     		Action 'VIEWDEF.TRETA011' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     		Action 'VIEWDEF.TRETA011' 	OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    		Action 'VIEWDEF.TRETA011' 	OPERATION 08 ACCESS 0
	ADD OPTION aRotina Title 'Copiar'      		Action 'VIEWDEF.TRETA011' 	OPERATION 09 ACCESS 0  
	ADD OPTION aRotina Title 'Limpar Identfid'	Action 'U_TRETE005()' 		OPERATION 02 ACCESS 0

Return aRotina


//-------------------------------------------------------------------
Static Function ModelDef()

Local oStruMHX := FWFormStruct( 1, 'MHX', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'TRETM011', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields( 'MHXMASTER', /*cOwner*/, oStruMHX )

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( 'Cadastro de Concentradoras' )

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({ "MHX_FILIAL" , "MHX_CODCON" })

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'MHXMASTER' ):SetDescription( 'Dados da Concentradora' )

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oStruMHX := FWFormStruct( 2, 'MHX' )

// Cria a estrutura a ser usada na View
Local oModel   := FWLoadModel( 'TRETA011' )

Local oView

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_MHX', oStruMHX, 'MHXMASTER' )

// Criar um "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'SUPERIOR', 100 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_MHX', 'SUPERIOR' )

// Liga a identificacao do componente
oView:EnableTitleView('VIEW_MHX','Dados da Concentradora')   

// Define fechamento da tela
oView:SetCloseOnOk( {||.T.} )

Return oView
