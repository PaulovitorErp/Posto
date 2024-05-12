#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETA005
Cadastro de identificadores utilizando MVC 

@author Wellington Gonçalves
@since 19/05/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA005()

Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias( 'U68' )
oBrowse:SetDescription( 'Cadastro de Identificadores' )   

// adiciona legenda no Browser
oBrowse:AddLegend( "U68_STATUS == '1'", "GREEN", "Ativado")
oBrowse:AddLegend( "U68_STATUS == '2'", "RED"  , "Desativado")

oBrowse:Activate()

Return NIL

/*/{Protheus.doc} MenuDef

@author pablo
@since 05/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MenuDef()     

Local aRotina := {}

ADD OPTION aRotina Title 'Pesquisar'   		Action 'PesqBrw'          	OPERATION 01 ACCESS 0
ADD OPTION aRotina Title 'Visualizar'  		Action 'VIEWDEF.TRETA005' 	OPERATION 02 ACCESS 0
ADD OPTION aRotina Title 'Incluir'     		Action 'VIEWDEF.TRETA005' 	OPERATION 03 ACCESS 0
ADD OPTION aRotina Title 'Alterar'     		Action 'VIEWDEF.TRETA005' 	OPERATION 04 ACCESS 0
ADD OPTION aRotina Title 'Excluir'     		Action 'VIEWDEF.TRETA005' 	OPERATION 05 ACCESS 0
ADD OPTION aRotina Title 'Imprimir'    		Action 'VIEWDEF.TRETA005' 	OPERATION 08 ACCESS 0
ADD OPTION aRotina Title 'Legenda'     		Action 'U_TRETC500()' 		OPERATION 10 ACCESS 0    
ADD OPTION aRotina Title 'Gravar Identfid'	Action 'U_TRETE003()' 		OPERATION 02 ACCESS 0   
ADD OPTION aRotina Title 'Apagar Identfid'	Action 'U_TRETE004()' 		OPERATION 02 ACCESS 0  

Return aRotina


/*/{Protheus.doc} ModelDef

@author pablo
@since 05/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ModelDef()

Local oStruU68 := FWFormStruct( 1, 'U68', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'TRETM005', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields( 'U68MASTER', /*cOwner*/, oStruU68 )

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( 'Cadastro de Identificadores' )

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({ "U68_FILIAL" , "U68_CODIGO" })

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'U68MASTER' ):SetDescription( 'Dados do cartão identificador' )

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
Local oStruU68 := FWFormStruct( 2, 'U68' )

// Cria a estrutura a ser usada na View
Local oModel   := FWLoadModel( 'TRETA005' )

Local oView

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_U68', oStruU68, 'U68MASTER' )

// Criar um "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'SUPERIOR', 100 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_U68', 'SUPERIOR' )

// Liga a identificacao do componente
oView:EnableTitleView('VIEW_U68','Dados do cartão identificador')   

// Define fechamento da tela
oView:SetCloseOnOk( {||.T.} )

Return oView        


/*/{Protheus.doc} TRETC500
Função que mostra a legenda dos cartões.

@author pablo
@since 05/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETC500()

	BrwLegenda("Status dos Cartões","Legenda", ;
		{ {"BR_VERDE","Cartão ativado"},;
		  {"BR_VERMELHO","Cartão desativado"} })

Return()