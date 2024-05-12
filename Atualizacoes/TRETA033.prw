#include "protheus.ch"  
#include "topconn.ch"  
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETA033
Cadastro Negociação de Preços - Vale Serviços
@author TOTVS
@since 27/04/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/

/***********************/
User Function TRETA033()
/***********************/

Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias("UI0")
oBrowse:SetDescription("Negociação de Preços - Vale Serviços")
oBrowse:Activate()

Return Nil

/************************/
Static Function MenuDef()
/************************/

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" 								ACTION "VIEWDEF.TRETA033" 	OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    								ACTION "VIEWDEF.TRETA033" 	OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    								ACTION "VIEWDEF.TRETA033" 	OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    								ACTION "VIEWDEF.TRETA033" 	OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE "Imprimir"   								ACTION "VIEWDEF.TRETA033" 	OPERATION 8 ACCESS 0
ADD OPTION aRotina TITLE "Atualização de Preços"    				ACTION "U_ATUUIB" 			OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Prc. Negociados X Grp. Cliente/Cliente"	ACTION "U_TRETR011"			OPERATION 8 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruUI0 := FWFormStruct(1,"UI0",/*bAvalCampo*/,/*lViewUsado*/ )
Local oStruUI1 := FWFormStruct(1,"UI1",/*bAvalCampo*/,/*lViewUsado*/ )
Local oStruUIB := FWFormStruct(1,"UIB",/*bAvalCampo*/,/*lViewUsado*/ )

Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TRETM033",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields("UI0MASTER",/*cOwner*/,oStruUI0)

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({"UI0_FILIAL","UI0_GRPCLI","UI0_CLIENT","UI0_LOJA"})

// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid("UI1DETAIL","UI0MASTER",oStruUI1,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*BLoad*/)
oModel:GetModel("UI1DETAIL"):SetNoInsertLine(.T.)
oModel:GetModel("UI1DETAIL"):SetNoUpdateLine(.T.)
oModel:GetModel("UI1DETAIL"):SetNoDeleteLine(.T.)

oModel:AddGrid("UIBDETAIL","UI1DETAIL",oStruUIB,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*BLoad*/)
oModel:GetModel("UIBDETAIL"):SetNoInsertLine(.T.)
oModel:GetModel("UIBDETAIL"):SetNoDeleteLine(.T.)

// Faz relaciomaneto entre os compomentes do model
oModel:SetRelation("UI1DETAIL", {{"UI1_FILIAL", 'xFilial("UI1")'},{"UI1_GRPCLI","UI0_GRPCLI"},{"UI1_CLIENT","UI0_CLIENT"},{"UI1_LOJA","UI0_LOJA"}},UI1->(IndexKey(1)))
oModel:SetRelation("UIBDETAIL", {{"UIB_FILIAL", 'xFilial("UIB")'},{"UIB_GRPCLI","UI0_GRPCLI"},{"UIB_CLIENT","UI0_CLIENT"},{"UIB_LOJA","UI0_LOJA"},{"UIB_FORNEC","UI1_FORNEC"},{"UIB_LOJAFO","UI1_LOJAFO"}},UIB->(IndexKey(1)))

// Desobriga a digitacao de ao menos um item
//oModel:GetModel("UIBDETAIL"):SetOptional(.T.)

// Liga o controle de nao repeticao de linha
oModel:GetModel("UI1DETAIL"):SetUniqueLine({"UI1_FORNEC","UI1_LOJAFO"})
oModel:GetModel("UIBDETAIL"):SetUniqueLine({"UIB_PRODUT"})

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription("Negociação de Preços - Vale Serviços")

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel("UI0MASTER"):SetDescription("Cliente/Grupo")
oModel:GetModel("UI1DETAIL"):SetDescription("Prestadores de Serviço")
oModel:GetModel("UIBDETAIL"):SetDescription("Preços negociados dos Serviços")

Return oModel

/************************/
Static Function ViewDef()
/************************/

// Cria a estrutura a ser usada na View
Local oStruUI0 := FWFormStruct(2,"UI0")
Local oStruUI1 := FWFormStruct(2,"UI1")
Local oStruUIB := FWFormStruct(2,"UIB")

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel("TRETA033")
Local oView

// Remove campos da estrutura
oStruUI1:RemoveField('UI1_GRPCLI')
oStruUI1:RemoveField('UI1_CLIENT')
oStruUI1:RemoveField('UI1_LOJA')
oStruUIB:RemoveField('UIB_GRPCLI')
oStruUIB:RemoveField('UIB_CLIENT')
oStruUIB:RemoveField('UIB_LOJA')
oStruUIB:RemoveField('UIB_FORNEC')
oStruUIB:RemoveField('UIB_LOJAFO')

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField("VIEW_UI0",oStruUI0,"UI0MASTER")

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid("VIEW_UI1",oStruUI1,"UI1DETAIL")
oView:AddGrid("VIEW_UIB",oStruUIB,"UIBDETAIL")

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox("CABEC" , 30)
oView:CreateHorizontalBox("ITENS" , 70)

oView:CreateVerticalBox("ITENS_E", 40, "ITENS")
oView:CreateVerticalBox("ITENS_D", 60, "ITENS")

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView("VIEW_UI0","CABEC")
oView:SetOwnerView("VIEW_UI1","ITENS_E")
oView:SetOwnerView("VIEW_UIB","ITENS_D")

// Liga a identificacao do componente
oView:EnableTitleView("VIEW_UI0")
oView:EnableTitleView("VIEW_UI1","Prestadores de Serviço",RGB(224,30,43))  
oView:EnableTitleView("VIEW_UIB","Preços negociados dos Serviços",RGB(224,30,43))  

bBloco := {|oView| IniCpCli(oView)}
oView:SetAfterViewActivate(bBloco) 

// Define campos que terao Auto Incremento
//oView:AddIncrementField("VIEW_UI1","U02_SEQBIC")

oView:SetCloseOnOk( {||.T.} )

Return oView 

/*********************/
User Function ATUUIB()
/*********************/

Local cQry 	:= ""
Local aPrc	:= {}
Local nI

If !ValidPerg()  
	Return
Endif 

If Select("QRYPRC") > 0
	QRYPRC->(DbCloseArea())
Endif

cQry := "SELECT UI0.UI0_GRPCLI, UI0.UI0_CLIENT, UI0.UI0_LOJA, UIB.UIB_PRODUT, UH9.UH9_PRCUNI, UIB.UIB_DESACR"
cQry += " FROM "+RetSqlName("UI0")+" UI0 INNER JOIN "+RetSqlName("UIB")+" UIB 	ON 	UI0.UI0_GRPCLI	= UIB.UIB_GRPCLI"
cQry += " 																		AND UI0.UI0_CLIENT	= UIB.UIB_CLIENT"
cQry += " 																		AND UI0.UI0_LOJA 	= UIB.UIB_LOJA"
cQry += " 																		AND UIB.D_E_L_E_T_	<> '*'"
cQry += " 																		AND UIB.UIB_FILIAL	= '"+xFilial("UIB")+"'"

cQry += "								INNER JOIN "+RetSqlName("UH9")+" UH9 	ON 	UIB.UIB_FORNEC	= UH9.UH9_FORNEC"
cQry += " 																		AND UIB.UIB_LOJAFO	= UH9.UH9_LOJA"
cQry += " 																		AND UIB.UIB_PRODUT	= UH9.UH9_PRODUT"
cQry += " 																		AND UH9.D_E_L_E_T_	<> '*'"
cQry += " 																		AND UH9.UH9_FILIAL	= '"+xFilial("UH9")+"'"

cQry += " WHERE UI0.D_E_L_E_T_	<> '*'"
cQry += " AND UI0.UI0_FILIAL	= '"+xFilial("UI0")+"'"
cQry += " AND UI0.UI0_GRPCLI	BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
cQry += " AND UI0.UI0_CLIENT	BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR05+"'"
cQry += " AND UI0.UI0_LOJA		BETWEEN '"+MV_PAR04+"' AND '"+MV_PAR06+"'"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETA033.txt",cQry)
TcQuery cQry NEW Alias "QRYPRC"

While QRYPRC->(!EOF())
	
	AAdd(aPrc,{QRYPRC->UI0_GRPCLI,;
				QRYPRC->UI0_CLIENT,;
				QRYPRC->UI0_LOJA,;
				QRYPRC->UIB_PRODUT,;
				QRYPRC->UH9_PRCUNI,;
				QRYPRC->UIB_DESACR})
	QRYPRC->(DbSkip())
EndDo

If Len(aPrc) > 0

	If MsgYesNo("Haverá atualização dos Preços Negociados conforme parâmetros informados, deseja continuar?")
		FWMsgRun(,{|| ProcAtuPrc(aPrc)},"Aguarde","Atualizando Preços...")
		MsgInfo("Preços Negociados atualizados.","Atenção")
	Endif
Else
	MsgInfo("De acordo com os parâmetros informados, não foram encontrados registros.","Atenção")
Endif

If Select("QRYPRC") > 0
	QRYPRC->(DbCloseArea())
Endif

Return

/*******************************/
Static Function ProcAtuPrc(aPrc)
/*******************************/

Local nI

DbSelectArea("UIB")
UIB->(DbSetOrder(2)) // UIB_FILIAL+UIB_GRPCLI+UIB_CLIENT+UIB_LOJA+UIB_PRODUT

For nI := 1 To Len(aPrc)
	
	If UIB->(DbSeek(xFilial("UIB")+aPrc[nI][1]+aPrc[nI][2]+aPrc[nI][3]+aPrc[nI][4]))
	
		RecLock("UIB",.F.)
	
		If MV_PAR07 == 1 // Aumento de Preços
			
			If MV_PAR08 == 1 // Preço Negociado
				
				If MV_PAR09 == 1 // Percentual
				
					UIB->UIB_DESACR := aPrc[nI][6] + ((aPrc[nI][5] + aPrc[nI][6]) * (MV_PAR10 / 100))
				
				Else // Valor
				
					UIB->UIB_DESACR := aPrc[nI][6] + MV_PAR10
				Endif
			
			Else // Preço Base
			
				If MV_PAR09 == 1 // Percentual
				
					UIB->UIB_DESACR := aPrc[nI][5] * (MV_PAR10 / 100)
				
				Else // Valor
				
					UIB->UIB_DESACR := MV_PAR10
				Endif
			Endif
		
		Else // Diminuição de preços
	
			If MV_PAR08 == 1 // Preço Negociado
			
				If MV_PAR09 == 1 // Percentual
				
					UIB->UIB_DESACR := aPrc[nI][6] - ((aPrc[nI][5] + aPrc[nI][6]) * (MV_PAR10 / 100))
				
				Else // Valor
				
					UIB->UIB_DESACR := aPrc[nI][6] - MV_PAR10
				Endif
			
			Else // Preço Base
			
				If MV_PAR09 == 1 // Percentual
				
					UIB->UIB_DESACR := (aPrc[nI][5] * (MV_PAR10 / 100)) * -1
				
				Else // Valor
				
					UIB->UIB_DESACR := MV_PAR10 * -1 
				Endif
			Endif
		Endif
		
		UIB->(MsUnlock())
	Endif
Next nI

Return

/**************************/
Static Function ValidPerg() 
/**************************/

Local cPerg := "TRETA033"

U_uAjusSx1(cPerg,"01","Grp. Cliente De		?","","","mv_ch1","C",06,0,0,"G","","ACY","","","mv_par01","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1(cPerg,"02","Grp. Cliente Ate		?","","","mv_ch2","C",06,0,0,"G","","ACY","","","mv_par02","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1(cPerg,"03","Cliente De			?","","","mv_ch3","C",06,0,0,"G","","SA1","","","mv_par03","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1(cPerg,"04","Loja De				?","","","mv_ch4","C",02,0,0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1(cPerg,"05","Cliente Ate			?","","","mv_ch5","C",06,0,0,"G","","SA1","","","mv_par05","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1(cPerg,"06","Loja Ate				?","","","mv_ch6","C",02,0,0,"G","","","","","mv_par06","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1(cPerg,"07","Operação				?","","","mv_ch7","C",01,0,0,"C","","","","","mv_par07","Aumento","","","","Diminuição","","","","" ,"","","","","","","")
U_uAjusSx1(cPerg,"08","Preço Base			?","","","mv_ch8","C",01,0,0,"C","","","","","mv_par08","Preço Negociado","","","","Preço Base","","","","" ,"","","","","","","")
U_uAjusSx1(cPerg,"09","Tipo					?","","","mv_ch9","C",01,0,0,"C","","","","","mv_par09","Percentual","","","","Valor","","","","" ,"","","","","","","")
U_uAjusSx1(cPerg,"10","Valor					?","","","mv_ch9","N",12,2,0,"G","","","","","mv_par10","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})

Return Pergunte(cPerg,.T.)

/********************************************/
User Function LoadUI1(cGrpCli,cCliente,cLoja)
/********************************************/

Local aArea			:= GetArea()
Local lRet			:= .T.
Local lContinua		:= .T.
Local nI
Local cQry			:= ""

Local oModel		:= FWModelActive() 
Local oView			:= FWViewActive()
Local oModelUI1 	:= oModel:GetModel("UI1DETAIL")
Local oModelUIB 	:= oModel:GetModel("UIBDETAIL")
Local nOperation 	:= oModel:GetOperation()

Local lLinOK		:= .F.

DbSelectArea("UI0")
UI0->(DbSetOrder(1)) //UI0_FILIAL+UI0_GRPCLI+UI0_CLIENT+UI0_LOJA

If !Empty(cGrpCli) .Or. (!Empty(cCliente) .And. !Empty(cLoja))

	If !UI0->(DbSeek(xFilial("UI0")+cGrpCli+cCliente+cLoja))

		For nI := 1 To oModelUI1:Length()
		
			oModelUI1:Goline(nI)  
		
			If !oModelUI1:IsDeleted()
				
				If !Empty(oModelUI1:GetValue("UI1_FORNEC"))
					
					lContinua := .F.
					oModelUI1:Goline(1)  
	
					If oView <> Nil
						oView:Refresh() 
					EndIf
					
					Exit
				EndIf
			Endif
		Next nI
		
		If lContinua
	
			oModel:GetModel("UI1DETAIL"):SetNoInsertLine(.F.)
			oModel:GetModel("UI1DETAIL"):SetNoUpdateLine(.F.)
			oModel:GetModel("UI1DETAIL"):SetNoDeleteLine(.F.)
			
			oModel:GetModel("UIBDETAIL"):SetNoInsertLine(.F.)
			oModel:GetModel("UIBDETAIL"):SetNoDeleteLine(.F.)
		
			// Seleciona os Prestadores de Serviços
			If Select("QRYUH8") > 0
				QRYUH8->(DbCloseArea())
			Endif
			
			cQry := "SELECT UH8_FORNEC, UH8_LOJA, UH8_NOME"
			cQry += " FROM "+RetSqlName("UH8")+""
			cQry += " WHERE D_E_L_E_T_	<> '*'"
			cQry += " AND UH8_FILIAL	= '"+xFilial("UH8")+"'"
			
			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\TRETA033.txt",cQry)
			TcQuery cQry NEW Alias "QRYUH8"
			
			If QRYUH8->(!EOF())
			
				While QRYUH8->(!EOF())
		
					// Se a primeira linha não estiver em branco, insere uma nova linha
					If !Empty(oModelUI1:GetValue("UI1_NOME")) 
						oModelUI1:AddLine()
						oModelUI1:GoLine(oModelUI1:Length())
					Endif
					
					oModelUI1:LoadValue("UI1_FORNEC",QRYUH8->UH8_FORNEC)
					oModelUI1:LoadValue("UI1_LOJAFO",QRYUH8->UH8_LOJA)
					oModelUI1:LoadValue("UI1_NOME",QRYUH8->UH8_NOME)
					
					//oView:Refresh("UI1DETAIL")
		
					// Carrega os serviços
					LoadUIB(QRYUH8->UH8_FORNEC,QRYUH8->UH8_LOJA,oModelUIB)
				
					QRYUH8->(DbSkip())
				EndDo
				
				oModelUI1:GoLine(1)
				oModelUIB:GoLine(1)
		
				If oView <> Nil
					oView:Refresh() 
				EndIf
			Endif
	
			If Select("QRYUH8") > 0
				QRYUH8->(DbCloseArea())
			Endif
		
			oModel:GetModel("UI1DETAIL"):SetNoInsertLine(.T.)
			oModel:GetModel("UI1DETAIL"):SetNoUpdateLine(.T.)
			oModel:GetModel("UI1DETAIL"):SetNoDeleteLine(.T.)
			
			oModel:GetModel("UIBDETAIL"):SetNoInsertLine(.T.)
			oModel:GetModel("UIBDETAIL"):SetNoDeleteLine(.T.)
		EndIf
	Else
		Help( ,, '',, 'Grupo de Cliente ou Cliente e Loja ja existente.', 1, 0 )
		lRet := .F.
	Endif
EndIf

RestArea(aArea)

Return lRet

/************************************************/
Static Function LoadUIB(cFornece,cLoja,oModelUIB)
/************************************************/

Local cQry	:= ""

Local oView	:= FWViewActive()

// Seleciona os Prestadores de Serviços
If Select("QRYUH9") > 0
	QRYUH9->(DbCloseArea())
Endif

cQry := "SELECT UH9_PRODUT, UH9_DESCRI, UH9_PRCUNI"
cQry += " FROM "+RetSqlName("UH9")+""
cQry += " WHERE D_E_L_E_T_	<> '*'"
cQry += " AND UH9_FILIAL	= '"+xFilial("UH9")+"'"
cQry += " AND UH9_FORNEC	= '"+cFornece+"'"
cQry += " AND UH9_LOJA		= '"+cLoja+"'"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETA033.txt",cQry)
TcQuery cQry NEW Alias "QRYUH9"

While QRYUH9->(!EOF())
	
	// Se a primeira linha não estiver em branco, insere uma nova linha
	If !Empty(oModelUIB:GetValue("UIB_PRODUT")) 
		oModelUIB:AddLine()
		oModelUIB:GoLine(oModelUIB:Length())
	Endif
	
	oModelUIB:LoadValue("UIB_PRODUT",QRYUH9->UH9_PRODUT)
	oModelUIB:LoadValue("UIB_DESCPR",QRYUH9->UH9_DESCRI)
	oModelUIB:LoadValue("UIB_PRCBAS",QRYUH9->UH9_PRCUNI)
	oModelUIB:LoadValue("UIB_DESACR",0)
	oModelUIB:LoadValue("UIB_PRCVEN",QRYUH9->UH9_PRCUNI)

	//oView:Refresh("UIBDETAIL")
	
	QRYUH9->(DbSkip())
EndDo

If oView <> Nil
	oView:Refresh() 
EndIf


If Select("QRYUH9") > 0
	QRYUH9->(DbCloseArea())
Endif
	
Return

/************************************/
User Function UTRETA33(cCli,cLojaCli)
/************************************/

Local aArea			:= GetArea()

Private Inclui		:= .F.
Private Altera		:= .F.

Public __cCli		:= cCli
Public __cLojaCli 	:= cLojaCli

Dbselectarea("UI0")
UI0->(dbsetorder(1)) //UI0_FILIAL+UI0_GRPCLI+UI0_CLIENT+UI0_LOJA 

If UI0->(dbseek(xFilial("UI0")+Space(TamSX3("UI0_GRPCLI")[1])+cCli+cLojaCli))
	Inclui		:= .F.
	Altera		:= .T.
	FWExecView('ALTERAR','TRETA033',4,,{|| .T. /*fecha janela no ok*/}) //Alteração
Else
	Inclui		:= .T.
	Altera		:= .F.
	FWExecView('INCLUIR','TRETA033',3,,{|| .T. /*fecha janela no ok*/}) //Inclusão
Endif

// Crio como private, pois o sistema irá sobrescrever as variaveis Public
Private __cCli		:= ""
Private __cLojaCli 	:= ""

RestArea(aArea)

Return

/******************************/
Static Function IniCpCli(oView)
/******************************/

Local nOperation := oView:GetOperation()

If nOperation == 3

	If AllTrim(FunName()) == "MATA030" .or. AllTrim(FunName()) == "CRMA980" // Origem Cad. Cliente  

		FwFldPut("UI0_CLIENT",__cCli,,,,.T.)
		FwFldPut("UI0_LOJA",__cLojaCli,,,,.T.)
		FwFldPut("UI0_NOME",Posicione("SA1",1,xFilial("SA1")+__cCli+__cLojaCli,"A1_NOME"))
		
		oView:Refresh()
	Endif
Endif

Return

/***********************/
User Function INICLUI0()
/***********************/

Local cRet := ""

If empty(UI1->UI1_GRPCLI)
	cRet := Posicione("SA1",1,xFilial("SA1")+UI1->UI1_CLIENT+UI1->UI1_LOJA,"A1_NOME")
Else
	cRet := Posicione("ACY",1,xFilial("ACY")+UI1->UI1_GRPCLI,"ACY_DESCRI")
Endif
	
Return cRet

/******************************/
User Function InfPrUIB(cOrigem)
/******************************/

Local nRet 			:= 0
Local cQry			:= ""

Local oModel		:= FWModelActive() 
Local oView			:= FWViewActive()
Local oModelUI1 	:= oModel:GetModel("UI1DETAIL")
Local nOperation 	:= oModel:GetOperation()

If nOperation <> 3 // Inclusão

	If Select("QRYUH9") > 0
		QRYUH9->(DbCloseArea())
	Endif
	
	cQry := "SELECT UH9_PRCUNI"
	cQry += " FROM "+RetSqlName("UH9")+""
	cQry += " WHERE D_E_L_E_T_	<> '*'"
	cQry += " AND UH9_FILIAL	= '"+xFilial("UH9")+"'"
	cQry += " AND UH9_FORNEC	= '"+oModelUI1:GetValue("UI1_FORNEC")+"'"
	cQry += " AND UH9_LOJA		= '"+oModelUI1:GetValue("UI1_LOJAFO")+"'"
	cQry += " AND UH9_PRODUT	= '"+UIB->UIB_PRODUT+"'"
	
	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETA033.txt",cQry)
	TcQuery cQry NEW Alias "QRYUH9"
	
	If QRYUH9->(!EOF())
		
		If cOrigem == "B" // Preço Base
			nRet := QRYUH9->UH9_PRCUNI
		Else // Preço Venda
			nRet := QRYUH9->UH9_PRCUNI + UIB->UIB_DESACR
		EndIf
	EndIf
EndIf

Return nRet
