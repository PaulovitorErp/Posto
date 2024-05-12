#include "protheus.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETA046
Cadastro Classe Cliente
@author Maiki
@since 21/11/2014
@version P11
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETA046()
/***********************/

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('UF6')
oBrowse:SetDescription('Classe Cliente')
oBrowse:Activate()

Return NIL

/************************/
Static Function MenuDef()
/************************/

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.TRETA046" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.TRETA046" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.TRETA046" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.TRETA046" OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE "Imprimir"   ACTION "VIEWDEF.TRETA046" OPERATION 8 ACCESS 0
//ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.TRETA046" OPERATION 9 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruUF6 := FWFormStruct(1,"UF6",/*bAvalCampo*/,/*lViewUsado*/)
Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TRETM046",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/)

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields("UF6MASTER",/*cOwner*/,oStruUF6,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/)

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({"UF6_FILIAL","UF6_CODIGO"})

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription("Classe Cliente")

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel("UF6MASTER"):SetDescription("Classe")

Return oModel

/************************/
Static Function ViewDef()
/************************/

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel := FWLoadModel("TRETA046")

// Cria a estrutura a ser usada na View
Local oStruUF6 := FWFormStruct(2,"UF6")

Local oView
Local cCampos := {}

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField("VIEW_UF6",oStruUF6,"UF6MASTER")

// Criar um "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox("TELA",100)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView("VIEW_UF6","TELA")

Return oView