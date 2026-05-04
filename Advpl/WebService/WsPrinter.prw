/**-------------------------------------------------------------------------------------------**/
/** NOME DO WEBSERVICE  : WsPrinter										            	      **/
/**-------------------------------------------------------------------------------------------**/
/**										CRIACAO / ALTERACOES / MANUTENCOES                    **/
/**-------------------------------------------------------------------------------------------**/
/** Data       	| Desenvolvedor          | Solicitacao         		| Descricao               **/
/**-------------------------------------------------------------------------------------------**/ 												  **/
/** 20/04/2026    | Jean Correa da Silva                 | -                    	|  		  **/
/**-------------------------------------------------------------------------------------------**/
/**                                 DECLARAÇÃO DAS BIBLIOTECAS                                **/
/**-------------------------------------------------------------------------------------------**/
#Include "rwmake.ch"
#Include "protheus.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"
#Include "totvs.ch"
#Include "restful.ch"
/**-------------------------------------------------------------------------------------------**/
/**                                  DEFINICAO DE PALAVRAS 	  			 						 		          **/
/**-------------------------------------------------------------------------------------------**/
#Define ENTER CHR(13)+CHR(10)


WSRESTFUL WsPrinter DESCRIPTION "Serviço para Reimprimir Etiqueta." FORMAT "application/json"

    WSDATA FILIAL AS String

    WSMETHOD POST DESCRIPTION "Serviço para reimpressão de etiquetas" WSSYNTAX "/WsPrinter"

END WSRESTFUL

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE WsPrinter


    Local cJson   	   := Self:GetContent()
    Local oJson		   := JsonObject():New()
    Local oIntegracao  := JsonObject():New()



    ::SetContentType("application/json")


    If !FWJsonDeserialize(cJson, @oJson)

        SetRestFault(500,'Parser Json Error')

    Else

        oIntegracao['response'] := "Reimpressao realizada com sucesso!"
        oIntegracao['status'] := .T.

        RpcClearEnv()
        RpcSetType(3)

        If RpcSetEnv("01", ::FILIAL)

            cOp			:= oJson:Op
            cIdZpl       := oJson:IdZpl
            nQuant       := oJson:Quant
            cLayout      := oJson:Layout

            QryTab(cOp)
            SOP->(DBGoTop())

            If Empty(cOp) .Or. Empty(cIdZpl) .Or. Empty(nQuant) .Or. Empty(cLayout)
                oIntegracao['response'] := "Parâmetros obrigatórios ausentes: 'Op' , 'IdZpl' , 'Quant' , 'Layout'."
                MsgAlert(oIntegracao:ToJson())
                Return .F.
            EndIf

            U_GERAPCB0(SOP->FILIAL, 'P', SOP->PRODUTO , cOp, nQuant, 'M', 'R', cLayout, SOP->ARMZ, '', cIdZpl)

        EndIf

    EndIf
    // Return oIntegracao['success']

    ::SetResponse(oIntegracao:toJson())

Return .T.

/**-----------------------------------------------------------------------------------------------------------------**/
/** NOME DA FUNCAO: SetErro                                                                                         **/
/** DESCRICAO     : Seta o erro e a mensagem para retorno no webservice                                             **/
/**-----------------------------------------------------------------------------------------------------------------**/
Static Function SetErro(cMsg, nCode)

    Default nCode := 400

    oIntegracao['response'] := FWhttpEncode(cMsg)
    oIntegracao['status'] 	:= .F.

    oRest:setStatusCode(nCode)

Return

/**-----------------------------------------------------------------------------------------------------------------**/
/** NOME DA FUNCAO: QryTab                                                                                          **/
/** DESCRICAO     : Realiza a consulta na tabela SC2 para obter os itens da OP    									**/
/** AUTOR	      : Jean Correa da Silva											                            	**/
/**-----------------------------------------------------------------------------------------------------------------**/

static function QryTab(cOp)

    Local aArea := GetArea()
    Local lRet 	:= .F.
    Local cQr 	:= ""

    cQr := " SELECT "
    cQr += "   SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN AS OP, "
    cQr += "   SC2.C2_PRODUTO AS PRODUTO, "
    cQr += "   SC2.C2_FILIAL AS FILIAL, "
    cQr += "   SC2.C2_LOCAL AS ARMZ, "
    cQr += "   SC2.C2_OBS AS OBS "
    cQr += " FROM " + RetSqlName("SC2") + " SC2 "
    cQr += " WHERE SC2.D_E_L_E_T_ = '' "
    cQr += "   AND SC2.C2_FILIAL = '" + xFilial("SC2") + "' "
    cQr += "   AND (SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN) = '" + AllTrim(cOp) + "' "
    cQr += " ORDER BY SC2.C2_NUM, SC2.C2_PRODUTO "
    vParada := '1'
    // abre a query
    TcQuery cQr new alias "SOP"
    SOP->(DBGoTop())

    if !empty(SOP->PRODUTO)
        lRet := .T.
    endif

    RestArea(aArea)

Return(lRet)
