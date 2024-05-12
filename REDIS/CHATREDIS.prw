/*
Prototipo de um chat para demonstracao de uso de Filas/Listas e servidor de cache
 
O usarios podem estar rodando em:
- diferentes servidores e servicos (Maquina1 (appserver.exe), Maquina2 (appserver.exe), ...) ou
- diferentes servicos (Maquina1 (appserver1.exe), Maquina1 (appserver2.exe), ...) ou
- mesmo servico (Maquina1 (appserver.exe)) ou
- qualquer combinacao acima
 
Configuracao:
  Para configurar no seu teste basta voce instalar e configurar o servico do Redis e atualizar
  o IP e a porta onde esta instalado:
  Ex: Redis maquina 10.172.32.7 e porta 6379
  cRedisServer := "10.172.32.7"
  nRedisPort   := 6379
  e/ou
  cFlLsServer  := "10.172.32.7"
  nFlLsPort    := 6379
Obs. se tiver instalado algum Redis com autenticacao nao esqueca de informar em "cRedisAuth" e/ou "cFlLsAuth"
Obs. os servicos de Cache do Redis e de Fila/Lista podem estar em servicos diferentes do Redis
 
 
Uso:
  u_ChatLogin
Obs. Abre a tela para fazer login de um usuario
 
 
Autor: Ricardo Castro Tavares de Lima (Ricardo Clima)
email: ricardo.clima@totvs.com.br
 
 
Versao usada no teste:
***  TOTVS S/A  ***
***  www.totvs.com.br  ***
* TOTVS - Build 7.00.170117A - Mar 14 2019 - 11:19:21
* Build: 64 bits
* SVN Revision: 22367
* Build Version: 17.3.0.9
*/

#include "protheus.ch"
#include "Fileio.ch"

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static cRedisServer     := "127.0.0.1"  // Endereco do servidor do Redis
Static nRedisPort       := 6379         // Porta do servidor do Redis
Static cRedisAuth       := ""           // Autenticacao do Redis
Static cFlLsServer      := "127.0.0.1"  // Endereco do servidor de Filas/Listas
Static nFlLsPort        := 6379         // Porta do servidor de Filas/Listas
Static cFlLsAuth        := ""           // Autenticacao do servidor de Filas/Listas

Static oRedis := Nil
Static oLista := Nil

#define LISTA_USUARIOS      "CHAT_LISTA_USUARIOS"
#define LISTA_CONVERSAS     "CHAT_LISTA_CONVERSAS"
#define LISTA_IMAGENS       "CHAT_LISTA_IMAGENS"

#define NOME_ARQ_IMAGEM     "_apagar.bmp"

Static cFimConversa := Chr(3) + "_FIM_DE_CONVERSA_"
Static cImagem      := Chr(3) + "_IMAGEM_"

#define PRT_ERROR(x)        ConOut(time() + " [Thr: " + Strzero(ThreadId(), 5) + "]" + " # ERROR # " + x)
#define PRT_MSG(x)          ConOut(time() + " [Thr: " + Strzero(ThreadId(), 5) + "]" + "           " + x)

#define PRE_CONVERSA        (time() + " -> ")

//////////////////////////////////////////////////////////////////////////////////////////////////////////

User Function ChatLogin
	Local oDlg1
	Local oButton1
	Local oButton2
	Local oButton3
	Local oButton4
	Local oGet1
	Private cGet1

	Public oList2
	Public aList := {}
	Public oOK := LoadBitmap(GetResources(),'br_verde')
	Public oNO := LoadBitmap(GetResources(),'br_vermelho')
	// Usuario Logado
	Public cUsuario := Nil

	Public oList3

	cGet1 := space(20)

	connect()

	DEFINE MSDIALOG oDlg1 FROM 0,0 TO 160,250 PIXEL TITLE "TOTVS CHAT - Velho Novo ADVPL"

	@ 01,01 SAY "Usuario:"
	@ 01,04 MSGET oGet1 VAR cGet1 SIZE 80,10

	oButton1 := tButton():New(30, 85, 'Login',          oDlg1, {|| AddUser()},           35, 15, ,,,.T.)
	oButton2 := tButton():New(30, 10, 'Logout',         oDlg1, {|| cUsuario := Nil},     35, 15, ,,,.T.)
	oButton3 := tButton():New(50, 10, 'LIMPAR CHAT',    oDlg1, {|| CleanAll()},          35, 15, ,,,.T.)
	oButton4 := tButton():New(50, 85, 'SAIR',           oDlg1, {|| oDlg1:End()},         35, 15, ,,,.T.)

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return Nil

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function AddUser()
	Local cCmd := Nil
	Local xRetCmd := Nil
	Local cMsg := Nil
	Local cLog := ""

	If(connect() == .F.)
		Return .F.
	EndIf

	cLog := AllTrim(cGet1)
	cGet1 := space(20)

	If(ValType(cLog) != 'C' .Or. Len(cLog) <=0)
		cMsg := "ta apressado ??? calma, digita o nome primeiro !!!  "
		MessageBox(cMsg, "Nome de usuario invalido", 48)
		PRT_ERROR(cMsg)

		Return .F.
	EndIf

	If(ValType(cUsuario) == 'C' .And. Len(cUsuario) > 0 .And. ! cUsuario == cLog)
		cMsg := "ta apressado mesmo !!! faca o Logout de '" + cUsuario + "'"
		MessageBox(cMsg, "Usuario ja Logado", 48)
		PRT_ERROR(cMsg)
		Return .F.
	EndIf

	cCmd := "SADD " + LISTA_USUARIOS + " '" + cLog + "'"
	If .Not. execCmd(cCmd, @xRetCmd)
		Return .F.
	EndIf

	If(ValType(xRetCmd) == 'N')
		// 1 - adicionou  | 0 - ja estava adicionado
		If(xRetCmd == 1 .Or. xRetCmd == 0)
			If(cUsuario == Nil)
				cUsuario := cLog
			EndIf

			TcUser()
			Return .T.
		Else
			PRT_ERROR("AddUser: " + cLog + " Retorno invalido: " + cValToChar(xRetCmd))
			VarInfo("AddUser", xRetCmd)
			Return .F.
		EndIf
	Else
		PRT_ERROR("AddUser: " + cLog + " Tipo invalido: " + ValType(xRetCmd))
		VarInfo("AddUser", xRetCmd)
		Return .F.
	EndIf

Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function AdcConversa(cConversa)
	Local cCmd := Nil
	Local xRetCmd := Nil

	If(connect() == .F.)
		Return .F.
	EndIf

	cCmd := "SADD " + LISTA_CONVERSAS + " '" + cConversa + "'"
	If .Not. execCmd(cCmd, @xRetCmd)
		Return .F.
	EndIf

	If(ValType(xRetCmd) == 'N')
		// 1 - adicionou  | 0 - ja estava adicionado
		If(xRetCmd == 1 .Or. xRetCmd == 0)
			Return .T.
		Else
			PRT_ERROR("AdcConversa: " + cConversa + " Retorno invalido: " + cValToChar(xRetCmd))
			VarInfo("AdcConversa", xRetCmd)
			Return .F.
		EndIf
	Else
		PRT_ERROR("AdcConversa: " + cConversa + " Tipo invalido: " + ValType(xRetCmd))
		VarInfo("AdcConversa", xRetCmd)
		Return .F.
	EndIf

Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function obtemLista(cNomeLista, aItens, cLog, cIgnora)
	Local nX := 0
	Local cCmd := Nil
	Local xRetCmd := Nil

	aItens := {}

	If(connect() == .F.)
		Return .F.
	EndIf

	cCmd := "SMEMBERS " + cNomeLista
	If .Not. execCmd(cCmd, @xRetCmd)
		Return .F.
	EndIf
	//VarInfo("obtemLista", xRetCmd)

	ASort(xRetCmd)

	For nX := 1 to Len(xRetCmd)
		If(cIgnora == Nil .Or. .Not. (cIgnora == xRetCmd[nX]))
			AAdd(aItens, {.F., xRetCmd[nX]})
			//PRT_MSG(cLog + "[" + cValToChar(nX) + "] = " + xRetCmd[nX])
		EndIf
	Next
	//VarInfo("aItens", aItens)

Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ListaConversas(aConv)
Return obtemLista(LISTA_CONVERSAS, @aConv, "Conversa", Nil)

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ListaUsers(aUsers, cUser)
// Se passar o usuario (cUsuario) filtra e nao mostra na lista (deixando por hora so para demonstracao erro ao se tentar conversar consigo mesmo)
	Local lRet := obtemLista(LISTA_USUARIOS, @aUsers, "Usuario", cUser)

	If(oList2 != Nil .And. Len(aUsers) > 0)
		// Seta o vetor a ser utilizado
		oList2:SetArray(@aUsers)

		// Monta a linha a ser exibida no Browse
		oList2:bLine := {||{ If(aUsers != Nil .And. oList2 != Nil .And. aUsers[oList2:nAt, 01], oOK, oNO), If(aUsers != Nil .And. oList2 != Nil, aUsers[oList2:nAt,02], ) } }
		// Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
		oList2:bLDblClick := {|| If(aUsers != Nil .And. oList2 != Nil, aUsers[oList2:nAt][1] := !aUsers[oList2:nAt][1], ), If(aUsers != Nil .And. oList2 != Nil, oList2:DrawSelect(), ), If(aUsers != Nil .And. oList2 != Nil, NovaConversa(aUsers[oList2:nAt][2]), ) }

		oList2:Refresh() // refresh da lista
	EndIf

Return lRet

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function TcUser()
	Local oDlg2

	DEFINE MSDIALOG oDlg2 FROM 0,0 TO 220,300 PIXEL TITLE 'Lista amigos de: ' + cUsuario + " - Velho Novo ADVPL"
	// Cria objeto de fonte que sera usado na Browse
	Define Font oFont Name 'Courier New' Size 0, -12
	// Cria Browse
	oList2 := TCBrowse():New(01 ,01, 120, 100, ,{'CHAT', 'Usuario'},{30, 50},oDlg2,,,,,{||},,oFont,,,,,.F.,,.T.,,.F.,,, )

	ListaUsers(@aList, /*cUsuario*/)

	nMilissegundos := 2000 // Disparo sera de 2 em 2 segundos
	oTimer := TTimer():New(nMilissegundos, {|| ListaUsers(@aList, /*cUsuario*/) }, oDlg2)
	oTimer:Activate()

	oList2:Refresh() // refresh da lista
	ACTIVATE MSDIALOG oDlg2 CENTERED
Return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function NovaConversa(cNovoUsuario)
	Local cMsg := ""

	If(cUsuario == Nil .Or. Len(cUsuario) <= 0)
		PRT_ERROR("Nao tem usuario Logado")
		Return .F.
	EndIf

	If(cUsuario == cNovoUsuario)
		cMsg := 'E "' + cUsuario + '" disse: ' + CRLF + '- Voce nao deve conversar com voce mesmo "' + cUsuario + '"'
		MessageBox(cMsg, "???", 48)
		PRT_ERROR(cMsg)
		Return .F.
	EndIf

	PRT_MSG(cUsuario + " iniciando com versa com: " + cNovoUsuario)

	TcConversa(cUsuario, cNovoUsuario)
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function TcConversa(cMeuUsuario, cNovoUsuario)
	Local oFilaEnv := Nil
	Local oFilaRec := Nil
	Local cQueueEnv := Nil
	Local cQueueRec := Nil
	Local nId := cMeuUsuario + "_" + cNovoUsuario
	Local cIdMsgEnv := ""
	Local aLstMsg := {}
	Local oBtEnv := Nil
	Local oBtImg := Nil
	Local oBtFim := Nil
	Local oMsgEnv := Nil
	Local oBmp := Nil
	Local cImgPath := ""
	Private cMsgEnv := ""
	Private oDlg3 := Nil

	PRT_MSG(nId + " " + cMeuUsuario + " conversando com " + cNovoUsuario)

	If(connect() == .F.)
		Return .F.
	EndIf

	AAdd(aLstMsg, {PRE_CONVERSA + ("conversa com " + cNovoUsuario), ""})

	cQueueEnv := LISTA_CONVERSAS + "_" + cMeuUsuario + "_" + cNovoUsuario
	cQueueRec := LISTA_CONVERSAS + "_" + cNovoUsuario + "_" + cMeuUsuario

	oFilaEnv := conFila(cQueueEnv)
	If(oFilaEnv == Nil)
		PRT_ERROR(nId + " Falhou criacao da fila: " + cQueueEnv)
		Return .F.
	EndIf
	If(!AdcConversa(cQueueEnv))
		Return .F.
	EndIf

	oFilaRec := conFila(cQueueRec)
	If(oFilaRec == Nil)
		PRT_ERROR(nId + " Falhou criacao da fila: " + cQueueRec)
		Return .F.
	EndIf
	If(!AdcConversa(cQueueRec))
		Return .F.
	EndIf

	DEFINE MSDIALOG oDlg3 FROM 0,0 TO 780,600 PIXEL TITLE 'Converva de ' + cMeuUsuario + " com o usuario " + cNovoUsuario
	// Cria objeto de fonte que sera usado na Browse
	Define Font oFont Name 'Courier New' Size 0, -12

	cMsgEnv := space(50)

	// Cria Browse
	oList3 := TCBrowse():New( 01 , 01, 300, 200,,{cMeuUsuario, cNovoUsuario},{150, 150},oDlg3,,,,,{||},,oFont,,,,,.F.,,.T.,,.F.,,, )

	@ 16,01 SAY "Mensagem:"
	@ 16,05 MSGET oMsgEnv VAR cMsgEnv SIZE 150,10
	oBtEnv := tButton():New(207, 210, 'Enviar',  oDlg3, {|| EnviaMensagem(nId, @oFilaEnv, @oFilaRec, oLista, @cIdMsgEnv, aLstMsg, .F., "")}, 35, 12, , , ,.T.)
	oBtImg := SButton():New(207, 260, 15,               {|| cImgPath := AllTrim(cGetFile("Arquivos BMP (*.bmp)|*.bmp", "Envio de Arquivo", 1, "", .F., GETF_LOCALHARD, .F., .T.)), oDlg3:Refresh(), EnviaMensagem(nId, @oFilaEnv, @oFilaRec, oLista, @cIdMsgEnv, aLstMsg, .F., cImgPath) }, oDlg3, .T., , )
	oBtFim := TButton():New(227, 260, 'FIM',     oDlg3, {|| EnviaMensagem(nId, @oFilaEnv, @oFilaRec, oLista, @cIdMsgEnv, aLstMsg, .T., "")}, 35, 12, , , ,.T.)

	LerMessagem(nId, @oFilaRec, @oFilaEnv, oLista, @aLstMsg, @oBmp)

	nMilissegundos := 1000 // Disparo sera de 1 em 1 segundos
	oTimer := TTimer():New(nMilissegundos, {|| LerMessagem(nId, @oFilaRec, @oFilaEnv, oLista, @aLstMsg, @oBmp) }, oDlg3)
	oTimer:Activate()

	//oList3:Refresh() // refresh da lista
	ACTIVATE MSDIALOG oDlg3 CENTERED
	//on init (oDlg3:gotop())
Return

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function EnviaMensagem(nId, oFlEnv, oFlRec, oLst, cIdMsgEnv, aLstMsg, lFim, cImg)
	Local nRet := 0
	Local cMyMsg := ""
	Local cMsgImg := ""

	If (oFlEnv == Nil)
		Return .F.
	EndIf

	If(lFim)
		cMyMsg := cFimConversa
		AAdd(aLstMsg, {PRE_CONVERSA + "#[FIM DE CONVERSA]#", ""})
	ElseIf(cImg != "")
		If(LeArq(cImg, @cMsgImg))
			cIdImg := UUIDRandom()
			nRet := oLst:PutMsg(cIdImg, cMsgImg)
			If nRet != 0
				PRT_ERROR(nId + " Erro ao enviar imagem" + " Erro: " + AllTrim(Str(nRet)))
				Return .F.
			Else
				PRT_MSG(nId + " Enviou  img Lista - " + oLst:cName + " com ID: " + cIdImg + " Tamanho: " + AllTrim(Str(Len(cMsgImg))))
			EndIf
			cMyMsg := cImagem + cIdImg
			AAdd(aLstMsg, {PRE_CONVERSA + "[enviou imagem: " + cImg + ". Tamanho: " + AllTrim(Str(Len(cMsgImg))) + "]", ""})
		Else
			PRT_ERROR(nId + " Erro ao enviar ler imagem: " + cImg)
			Return .F.
		EndIf
	Else
		cMyMsg := AllTrim(cMsgEnv)

		// Nao manda mensagens sem conteudo (remove espacos inicio e fim)
		If(Len(cMyMsg) <= 0)
			cMsgEnv := space(50)
			Return .F.
		EndIf

		AAdd(aLstMsg, {PRE_CONVERSA + cMyMsg, ""})
	EndIf
	cMsgEnv := space(50)

	nRet := oFlEnv:PutMsg(@cIdMsgEnv, cMyMsg)
	If nRet != 0
		PRT_ERROR(nId + "Erro ao enviar mensagem" + " Erro: " + AllTrim(Str(nRet)))
		Return .F.
	Else
		PRT_MSG(nId + " Enviou  msg Fila  - " + oFlEnv:cName + " com ID: " + cIdMsgEnv + " Tamanho: " + AllTrim(Str(Len(cMyMsg))))
	EndIf
	If(lFim)
		// Obs. Poderia finalizar todas as referencias da conversa aqui
		oFlEnv := Nil
		oFlRec := Nil
	EndIf
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function LerMessagem(nId, oFlRec, oFlEnv, oLst, aLstMsg, oImg)
	Local cIdMsg := ""
	Local cMsg := ""
	Local cIdImg := ""
	Local cMsgImg := ""
	Local nRet := 0
	Local lConversando := .T.
	Local lRet := .F.
	Local lRecNewMsg := .F.

	While(lConversando .And. oFlRec != Nil)
		nRet := oFlRec:WaitMsg(@cIdMsg, @cMsg, , 0)
		If nRet != 0
			If(nRet == oFlRec:eNO_MSGS)
				//PRT_MSG(nId + " " + oFlRec:cName + " OK, nao existem mensagens na Fila")
				lRet := .T.
				lConversando := .F.
				Exit
			Else
				PRT_ERROR(nId + "Erro ao receber mensagem" + " Erro: " + AllTrim(Str(nRet)))
				lRet := .F.
				Exit
			EndIf
		Else
			PRT_MSG(nId + " Recebeu msg Fila  - " + oFlRec:cName + " com ID: " + cIdMsg + " Tamanho: " + AllTrim(Str(Len(cMsg))) + " msg: |" + cMsg + "|")
			nRet := oFlRec:DelMsg(cIdMsg)
			If nRet != 0
				PRT_ERROR(nId + " Erro ao remover mensagem tratada" + " com ID: " + cIdMsg + " Erro: " + AllTrim(Str(nRet)))
				lRet := .F.
				Exit
			Else
				PRT_MSG(nId + " Removeu msg Fila  - " + oFlRec:cName + " com ID: " + cIdMsg + " Tamanho: " + AllTrim(Str(Len(cMsg))))
			EndIf

			If(cMsg == cFimConversa)
				AAdd(aLstMsg, {"", PRE_CONVERSA + "#[SAIU DA CONVERSA]#"})
				lRecNewMsg := .T.
				PRT_MSG(nId + " Saindo da conversa")
				lRet := .F.

				// Obs. Poderia finalizar todas as referencias da conversa aqui
				oFlRec := Nil
				oFlEnv := Nil
				Exit
			ElseIf(cMsg = cImagem)
				cIdImg := SubStr(cMsg, Len(cImagem)+1)
				PRT_MSG(nId + " Procurando Imagem: " + cIdImg)
				nRet := oLst:GetMsg(cIdImg, @cMsgImg)
				If nRet != 0
					PRT_ERROR(nId + "Erro ao receber imagem" + " Erro: " + AllTrim(Str(nRet)))
					lRet := .F.
					Exit
				Else
					PRT_MSG(nId + " Recebeu img Lista - " + oLst:cName + " com ID: " + cIdImg + " Tamanho: " + AllTrim(Str(Len(cMsgImg))))
				EndIf
				nRet := oLst:DelMsg(cIdImg)
				If nRet != 0
					PRT_ERROR(nId + " Erro ao remover mensagem fila imagens " + " com ID: " + cIdImg + " Erro: " + AllTrim(Str(nRet)))
					lRet := .F.
					Exit
				Else
					PRT_MSG(nId + " Removeu img Lista - " + oLst:cName + " com ID: " + cIdImg + " Tamanho: " + AllTrim(Str(Len(cMsgImg))))
				EndIf
				PRT_MSG(nId + " Achou Imagem: " + cIdImg)

				If(.Not. GravaArq(NOME_ARQ_IMAGEM, cMsgImg))
					PRT_ERROR(nId + " Erro ao gravar imagem" + " com ID: " + cIdMsg)
					lRet := .F.
					Exit
				Else
					//PRT_MSG(nId + " Gravou Imagem: " + NOME_ARQ_IMAGEM)
				EndIf

				AAdd(aLstMsg, {"", PRE_CONVERSA + "[recebeu imagem. Tamanho: " + AllTrim(Str(Len(cMsgImg))) + "]"})
				lRecNewMsg := .T.

				If(oImg != Nil)
					oImg:Free()
				EndIf

				oImg := TBitMap():New(230, 10, 180, 150, , NOME_ARQ_IMAGEM, .F., oDlg3, , , , .T., , , , , .T.)
				oImg:Refresh()

				If(.Not. RemoveArq(NOME_ARQ_IMAGEM))
					PRT_ERROR(nId + " Erro ao remover imagem" + " com ID: " + NOME_ARQ_IMAGEM)
					lRet := .F.
					Exit
				Else
					//PRT_MSG(nId + " Removeu Imagem: " + NOME_ARQ_IMAGEM)
				EndIf
			Else
				AAdd(aLstMsg, {"", PRE_CONVERSA + cMsg})
				lRecNewMsg := .T.
			EndIf
		EndIf
	End

	If(oList3 != Nil .And. Len(aLstMsg) > 0)
		// Seta o vetor a ser utilizado
		oList3:SetArray(@aLstMsg)

		// Monta a linha a ser exibida no Browse
		oList3:bLine := {||{ aLstMsg[oList3:nAt, 01], aLstMsg[oList3:nAt,02] } }

		If(lRecNewMsg)
			oList3:GoDown()
		EndIf

		oList3:Refresh() // refresh da lista
	EndIf

Return lRet

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function connect()
	If(oLista == Nil)
		If(.Not. conLista(@oLista, LISTA_IMAGENS))
			Return .F.
		EndIf
	Else
	EndIf
	If(oRedis == Nil)
		oRedis := tRedisClient():New()
		oRedis:Connect(cRedisServer, nRedisPort, cRedisAuth)

		If oRedis:isConnected()
			PRT_MSG("Redis conectado.")
			Return .T.
		Else
			PRT_ERROR("Falha de conexao com o Redis.")

			oRedis:Disconnect()
			oRedis := Nil
			Return .F.
		EndIf
	Else
		Return .T.
	EndIf
Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function conFila(cNome)
	Local oFila := Nil
	Local nRet := 0
	Local nMsgRetPeriod := 60
	Local nVisibTimeOut := 5

	If(oFila == Nil)
		oFila := TQueueSvc():New(cNome)

		// Configurando a Fila
		nRet := oFila:Setup(cFlLsServer, nFlLsPort, cFlLsAuth, nMsgRetPeriod, nVisibTimeOut)

		If (nRet == 0)
			PRT_MSG("Setup de Fila OK: " + oFila:cName)
			Return oFila
		Else
			PRT_ERROR("Falha de conexao com a Fila: " + oFila:cName + " Erro: " + cValToChar(nRet))
			oFila := Nil
		EndIf
	Else
		Return oFila
	EndIf
Return Nil

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function conLista(oList, cNome)
	Local nRet := 0
	Local nMsgRetPeriod := 60

	If(oList == Nil)
		oList := TListSvc():New(cNome)

		// Configurando a Lista
		nRet := oList:Setup(cFlLsServer, nFlLsPort, cFlLsAuth, nMsgRetPeriod)
		//nRet := oList:Setup(cFlLsServer, nFlLsPort,            nMsgRetPeriod)

		If (nRet == 0)
			PRT_MSG("Setup de Lista OK: " + oList:cName)
			Return .T.
		Else
			PRT_ERROR("Falha de conexao com a Lista: " + oList:cName + " Erro: " + cValToChar(nRet))
			oList := Nil
		EndIf
	Else
		Return .T.
	EndIf
Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function CleanAll()
	Local nX := 0
	Local aUsrs := {}
	Local aConv := {}
	Local lRet := 0

	If(connect() == .F.)
		Return .F.
	EndIf

	ListaConversas(@aConv)
	For nX := 1 to Len(aConv)
		lRet := CleanFila(aConv[nX][2])
		If(lRet)
			CleanConversa(aConv[nX][2])
		EndIf
	Next

	ListaUsers(@aUsrs, Nil)
	For nX := 1 to Len(aUsrs)
		CleanUser(aUsrs[nX][2])
	Next

	CleanLista()

Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function CleanFila(cNome)
	Local oFila := Nil
	Local nRet  := 0

	If(connect() == .F.)
		Return .F.
	EndIf

	oFila := conFila(cNome)
	If(oFila == Nil)
		PRT_ERROR(nId + " Falhou Setup da fila: " + cNome)
		Return .F.
	EndIf

	nRet := oFila:Destroy()

	If nRet != 0
		PRT_ERROR("Falhou remocao da fila: " + cNome + " erro: " + cValToChar(nRet))
		Return .F.
	Else
		oFila := Nil
		PRT_MSG("Removeu fila: " + cNome)
		Return .T.
	EndIf
Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function CleanLista()
	Local nRet  := 0

	If(oLista == Nil)
		Return .T.
	Else
	EndIf

	nRet := oLista:Destroy()
	If nRet != 0
		PRT_ERROR("Falhou remocao da lista: " + LISTA_IMAGENS + " erro: " + cValToChar(nRet))
		Return .F.
	Else
		oLista := Nil
		PRT_MSG("Removeu lista: " + LISTA_IMAGENS)
		Return .T.
	EndIf
Return .F.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function CleanItem(cNomeLista, aItem, cLog)
	Local cCmd := Nil
	Local xRetCmd := Nil

	If(connect() == .F.)
		Return .F.
	EndIf

	cCmd := "SREM " + cNomeLista + " '" + aItem + "'"
	PRT_MSG('Removendo ' + cLog + ': "' + aItem + '" ...')
	If .Not. execCmd(cCmd, @xRetCmd)
		Return .F.
	EndIf

	//VarInfo("CleanItem " + cLog, xRetCmd)

Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function CleanUser(cUsr)
Return CleanItem(LISTA_USUARIOS, cUsr, "Usuario")

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function CleanConversa(cConv)
Return CleanItem(LISTA_CONVERSAS, cConv, "Conversa")

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function execCmd(cCmd, xRetCmd)
	If .Not. oRedis:exec(cCmd, @xRetCmd):ok()
		PRT_ERROR('Cmd: "' + cCmd + '" erro: ' + Alltrim(Str(oRedis:nError)) + " | " + AllTrim(oRedis:cError))
		Return .F.
	EndIf
Return .T.

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function LeArq(cArq, cRet)
	Local nBloco  := 512
	Local cBuffer := Space(512)
	Local nBytes  := 0
	Local hArq    := 0
	Local lRet    := .T.

	cRet := ""
	hArq := FOpen(cArq) // Abre o arquivo binario

	If FError() <> 0
		PRT_ERROR("Arquivo: " + cArq + " Erro de acesso ao arquivo nº " + Str(FError()))
		Return .F.
	EndIf

	While FError() == 0
		nBytes := FRead(hArq, @cBuffer, nBloco) // Le os bytes
		If nBytes < 0
			PRT_ERROR("Arquivo: " + cArq + " Erro de leitura nº " + Str(FError()))
			lRet := .F.
			Exit
		ElseIf nBytes == 0
			PRT_MSG("Arquivo: " + cArq + " lido corretamente")
			lRet := .T.
			Exit
		Else
			cRet += cBuffer
		EndIf
	End
	FClose(hArq) // Fecha o arquivo
Return lRet

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function GravaArq(cArq, cConteudo)
	Local nBytes  := 0
	Local hArq    := 0
	Local lRet    := .T.

	cRet := ""
	hArq := FCreate(cArq, FC_NORMAL) // Abre o arquivo para gravacao

	If FError() <> 0
		PRT_ERROR("Arquivo: " + cArq + " Erro de acesso ao arquivo nº " + Str(FError()))
		Return .F.
	EndIf

	nBytes := FWrite(hArq, cConteudo) // Grava os bytes
	If nBytes != Len(cConteudo)
		PRT_ERROR("Arquivo: " + cArq + " Erro de gravacao nº " + Str(FError()))
		lRet := .F.
	Else
		//PRT_MSG("Arquivo: " + cArq + " gravado corretamente.")
		lRet := .T.
	EndIf

	FClose(hArq) // Fecha o arquivo

Return lRet

//////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function RemoveArq(cArq)
	Local lRet    := .T.
	Local nRet    := 0

	nRet := FErase(cArq) // Remove o arquivo
	If nRet != 0
		PRT_ERROR("Arquivo: " + cArq + " Erro de remocao nº " + Str(FError()) + " ret: "  + AllTrim(Str(nRet)))
		lRet := .F.
	Else
		//PRT_MSG("Arquivo: " + cArq + " removido corretamente.")
		lRet := .T.
	EndIf

Return lRet

//////////////////////////////////////////////////////////////////////////////////////////////////////////
