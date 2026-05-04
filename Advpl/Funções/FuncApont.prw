#Include "protheus.ch"
#Include "totvs.ch"
#Include "restful.ch"
#Include "rwmake.ch"
#Include "topconn.ch"


/**-------------------------------------------------------------------------------------------     **/
/** NOME DA FUNCAO : QryTab                                                                        **/
/** DESCRICAO      : Consulta na Op                                                                **/
/**-------------------------------------------------------------------------------------------     **/
/** Data        | Desenvolvedor         | Solicitacao        | Descricao                           **/
/**-------------------------------------------------------------------------------------------     **/
/** 28/04/2025  | Jean Correa da Silva  | -               | Consulta na OP                         **/
/**-------------------------------------------------------------------------------------------     **/

User function QryTab(cOp)

    Local aArea := GetArea()
    Local lRet 	:= .F.
    Local cQr 	:= ""


    cQr += " SELECT "
    cQr += "   SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN AS OP, "
    cQr += "   SC2.C2_PRODUTO     AS PRODUTO, "
    cQr += "   SC2.C2_FILIAL      AS FILIAL, "
    cQr += "   SC2.C2_LOCAL       AS ARMZ, "
    cQr += "   SC2.C2_OBS         AS OBS, "
    cQr += "   SB1.B1_DESC        AS DESCRI, "
    cQr += "   SC2.C2_QUANT       AS QUANT, "
    cQr += "   SC2.C2_DATPRI      AS DATPRI, "
    cQr += "   SC2.C2_DATRF       AS DATRF, "
    cQr += "   SC2.C2_DATPRF      AS DATPRF, "
    cQr += "   SC2.C2_EMISSAO     AS EMISSAO, "
    cQr += "   SC2.C2_XNFISC      AS NF, "
    cQr += "   SC2.C2_QUJE        AS QUJE, "
    cQr += "   SC2.C2_TPOP        AS TPOP, "
    cQr += "   SC2.C2_STATUS      AS STATUS, "
    cQr += "   SC2.C2_ROTEIRO     AS ROTEIRO, "

    /* ======= STATUS OPERACIONAL ======== */
    cQr += "   CASE "

    /* Prevista */
    cQr += "     WHEN SC2.C2_TPOP = 'P' THEN 'Prevista' "

    /* Em Aberto: liberada, sem movimentos; DATRF nulo/blank/19000101 */
    cQr += "     WHEN SC2.C2_TPOP = 'F' "
    cQr += "      AND (SC2.C2_DATRF IS NULL OR SC2.C2_DATRF = '' OR SC2.C2_DATRF = '19000101') "
    cQr += "      AND (SELECT COUNT(*) FROM " + RetSqlName("SD3") + " SD3 "
    cQr += "            WHERE SD3.D3_OP = SC2.C2_NUM+SC2.C2_ITEM+SC2.C2_SEQUEN "
    cQr += "              AND SD3.D_E_L_E_T_='' ) = 0 "
    cQr += "      AND (SELECT COUNT(*) FROM " + RetSqlName("SH6") + " SH6 "
    cQr += "            WHERE SH6.H6_OP = SC2.C2_NUM+SC2.C2_ITEM+SC2.C2_SEQUEN "
    cQr += "              AND SH6.D_E_L_E_T_='' ) = 0 "
    cQr += "      AND DATEDIFF(DAY, SC2.C2_DATPRI, GETDATE()) < IIF(SC2.C2_DIASOCI=0,1,SC2.C2_DIASOCI) "
    cQr += "     THEN 'Em aberto' "

    /* Iniciada: liberada, sem DATRF efetivo, com movimentos em SD3/SH6, dentro do prazo */
    cQr += "     WHEN SC2.C2_TPOP = 'F' "
    cQr += "      AND (SC2.C2_DATRF IS NULL OR SC2.C2_DATRF = '' OR SC2.C2_DATRF = '19000101') "
    cQr += "      AND ( (SELECT COUNT(*) FROM " + RetSqlName("SD3") + " SD3 "
    cQr += "              WHERE SD3.D3_OP = SC2.C2_NUM+SC2.C2_ITEM+SC2.C2_SEQUEN "
    cQr += "                AND SD3.D_E_L_E_T_='' ) > 0 "
    cQr += "         OR  (SELECT COUNT(*) FROM " + RetSqlName("SH6") + " SH6 "
    cQr += "              WHERE SH6.H6_OP = SC2.C2_NUM+SC2.C2_ITEM+SC2.C2_SEQUEN "
    cQr += "                AND SH6.D_E_L_E_T_='' ) > 0 ) "
    cQr += "      AND DATEDIFF(DAY, SC2.C2_EMISSAO, GETDATE()) < IIF(SC2.C2_DIASOCI=0,1,SC2.C2_DIASOCI) "
    cQr += "     THEN 'Iniciada' "

    /* Ociosa: liberada, sem DATRF efetivo e prazo estourado */
    cQr += "     WHEN SC2.C2_TPOP = 'F' "
    cQr += "      AND (SC2.C2_DATRF IS NULL OR SC2.C2_DATRF = '' OR SC2.C2_DATRF = '19000101') "
    cQr += "      AND ( DATEDIFF(DAY, SC2.C2_EMISSAO, GETDATE()) > SC2.C2_DIASOCI "
    cQr += "         OR  DATEDIFF(DAY, SC2.C2_DATPRI, GETDATE()) >= SC2.C2_DIASOCI ) "
    cQr += "     THEN 'Ociosa' "

    /* Enc. Parcial: DATRF efetivo e quantidade produzida < solicitada */
    cQr += "     WHEN SC2.C2_TPOP = 'F' "
    cQr += "      AND (SC2.C2_DATRF IS NOT NULL AND SC2.C2_DATRF <> '' AND SC2.C2_DATRF <> '19000101') "
    cQr += "      AND SC2.C2_QUJE < SC2.C2_QUANT "
    cQr += "     THEN 'Enc. Parcial' "

    /* Enc. Total: DATRF efetivo e quantidade produzida >= solicitada */
    cQr += "     WHEN SC2.C2_TPOP = 'F' "
    cQr += "      AND (SC2.C2_DATRF IS NOT NULL AND SC2.C2_DATRF <> '' AND SC2.C2_DATRF <> '19000101') "
    cQr += "      AND SC2.C2_QUJE >= SC2.C2_QUANT "
    cQr += "     THEN 'Enc. Total' "

    cQr += "     ELSE 'Indeterminado' "
    cQr += "   END AS STATUS_OP "

    cQr += " FROM " + RetSqlName("SC2") + " SC2 "
    cQr += " LEFT JOIN " + RetSqlName("SB1") + " SB1 "
    cQr += "   ON SB1.D_E_L_E_T_ = '' "
    cQr += "  AND SB1.B1_FILIAL = SUBSTRING(SC2.C2_FILIAL,1,6) "
    cQr += "  AND SB1.B1_COD = SC2.C2_PRODUTO "
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

/*-------------------------------------------------------------------------------------------*/
/* NOME DA Função : DecideRoteiro                                                            */
/* Descrição      : Determina qual roteiro (01/02) deve ser usado na produção                */
/*-------------------------------------------------------------------------------------------*/
User Function DecideRoteiro(_cProduto)
    Local aArea    := GetArea()
    Local cQry     := ""
    Local cRoteiro := NIL

    cQry += " SELECT '02' AS ROTEIRO_ESCOLHIDO " + CRLF
    cQry += " FROM " + RetSqlName("SG2") + " SG2 " + CRLF
    cQry += " WHERE SG2.D_E_L_E_T_ = ' ' " + CRLF
    cQry += "   AND SG2.G2_FILIAL  = '" + XFilial("SG2") + "' " + CRLF
    cQry += "   AND SG2.G2_PRODUTO = '" + _cProduto + "' " + CRLF
    cQry += "   AND SG2.G2_CODIGO  = '02' " + CRLF

    TcQuery cQry New Alias "QRY_SG2"
    QRY_SG2->(DbGoTop())

    If !QRY_SG2->(Eof()) .AND. !Empty(QRY_SG2->ROTEIRO_ESCOLHIDO)
        cRoteiro := QRY_SG2->ROTEIRO_ESCOLHIDO
    EndIf

    QRY_SG2->(DbCloseArea())
    RestArea(aArea)

Return cRoteiro


/*-------------------------------------------------------------------------------------------*/
/* NOME DA FUNÇÃO : SetErro                                                                  */
/* DESCRIÇÃO      : Retorna erro padronizado no formato JSON para WebService                 */
/*-------------------------------------------------------------------------------------------*/
User Function SetErro(cMsg, nCode)

    Default nCode := 400

    oResponse['response'] := FWhttpEncode(cMsg)
    oResponse['success']  := .F.

    oRest:setStatusCode(nCode)

Return


/**-------------------------------------------------------------------------------------------**/
/** NOME DA FUNÇÃO: AESTA36											        	              **/
/** DESCRIÇÃO	    : Faz a validação do usuário 									          **/
/**-------------------------------------------------------------------------------------------**/
User Function VldUser(cUsrCB1)

    Local aArea := GetArea()
    Local lRet  := .F.
    Local cQry  := ""

    // --- Monta o SELECT ---
    cQry := "SELECT CB1_CODOPE "
    cQry += "FROM " + RetSqlName("CB1") + " "
    cQry += "WHERE D_E_L_E_T_ = '' "
    cQry += "  AND CB1_FILIAL = '" + xFilial("CB1") + "' "
    cQry += "  AND CB1_CODOPE = '" + AllTrim(cUsrCB1) + "'"

    // --- Executa a query ---
    TcQuery cQry New Alias "QRY_CB1"

    QRY_CB1->(DbGoTop())

    If !QRY_CB1->(EoF())
        lRet := .T.
    EndIf

    // --- Fecha query e restaura área ---
    QRY_CB1->(DbCloseArea())
    RestArea(aArea)

Return lRet

