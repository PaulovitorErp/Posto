#include "protheus.ch"
#include "topconn.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETA009
Numeração LMC
@author TOTVS
@since 17/10/2014
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETA009()
/***********************/
	
Local oBrowse

Private aRotina 	:= {}

oBrowse := FWmBrowse():New()
oBrowse:SetAlias("UB4")
oBrowse:SetDescription("Numeração Livro")   
oBrowse:Activate()

Return Nil

/************************/
Static Function MenuDef()
/************************/

aRotina 	:= {}

ADD OPTION aRotina Title 'Visualizar' 			Action "VIEWDEF.TRETA009"	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title "Incluir"    			Action "VIEWDEF.TRETA009"	OPERATION 3 ACCESS 0
ADD OPTION aRotina Title "Alterar"    			Action "VIEWDEF.TRETA009"	OPERATION 4 ACCESS 0
ADD OPTION aRotina Title "Excluir"    			Action "VIEWDEF.TRETA009"	OPERATION 5 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruUB4 := FWFormStruct(1,"UB4",/*bAvalCampo*/,/*lViewUsado*/ )

Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TRETM009",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields("UB4MASTER",/*cOwner*/,oStruUB4)

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({"UB4_FILIAL","UB4_CODIGO"})

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel("UB4MASTER"):SetDescription("Numeração Livro")

Return oModel

/************************/
Static Function ViewDef()
/************************/

// Cria a estrutura a ser usada na View
Local oStruUB4 := FWFormStruct(2,"UB4")

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel("TRETA009")
Local oView

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel(oModel)

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField("VIEW_UB4",oStruUB4,"UB4MASTER")

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox("PAINEL_CABEC", 100)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView("VIEW_UB4","PAINEL_CABEC")

// Liga a identificacao do componente
oView:EnableTitleView("VIEW_UB4","Numeração Livro")

// Define fechamento da tela ao confirmar a operação
oView:SetCloseOnOk( {||.T.} )

Return oView